#!/usr/bin/perl

#
# instespeak.pl - High Level Speech Processor
#
#

use strict;

# These Glib/Gtk2/Gnome2 are used for grabbing the current window
use Glib qw/TRUE FALSE/;
use Gtk2 '-init';
use Gnome2::Wnck;
use DBI;

# For connection to the java opennlp java instance
use IO::Socket;

my $cmds;

my $command_to_execute = "";

my $screen = "";
my $active_window = "";

my $pid = "";

my $initial_run = 1;

my @weather_report_output_records = ();
my $weather_report_record = "";
my $weather_temperature = "";
my $weather_windchill = "";
my $previous_command = "";

my @opennlp_output = "";
my $opennlp_record = "";

my @config_file_records = ();
my $config_file_record = "";

my $log_level = "";
my $project_dir = "";
 
my $date_and_time = `date`;
chomp ($date_and_time); 
 
my $version = "0.01"; 
 
system ("clear");
 
open (CFGFILE, "/etc/instespeak.cfg");

@config_file_records = <CFGFILE>;

close (CFGFILE);

foreach $config_file_record (@config_file_records) {
	chomp ($config_file_record);
	
	if ($config_file_record =~ m/(log_level)(\s*)(=)(\s*)(.*)/) {
		$log_level = $5;
		
		$log_level =~ s/\"//g;
	}
	
	elsif ($config_file_record =~ m/(project_directory)(\s*)(=)(\s*)(.*)/) {
		$project_dir = $5;
		
		$project_dir =~ s/\"//g;	
	}
}

# Capture ctrl-c
$SIG{INT} = \&exit_program;

# log file here:
open (STDOUT, "| tee -a $project_dir/logs/instespeak.log");

if ($log_level >= 1) {
	print "---------"x10 . "\n";
	print "Welcome to instespeak version $version!\n\n";
	print "Date and time: $date_and_time\n";
}

if ($log_level >= 5) {
	print "The current log level is: $log_level\n";
	print "The current project directory is: $project_dir\n";
}

if ($log_level >= 1) {
	print "---------"x10 . "\n";
}


my $socket = "";
my $pos_tagged_output = "";

my @pos_tags = ();
my $pos_tag = "";

my $text = "";
my $part_of_speech = "";

my $dbfile = "/mnt/projects/speech/instespeak/instespeak.db";
my $database_handle = DBI->connect ("dbi:SQLite:dbname=$dbfile", "", "");

my $sql_query = "";
my $sql_query_prepare = "";
my $sql_query_return_value = "";

my @noun_row_select_results = ();
my $noun_row_select_result = "";

my $module_to_run = "";
my $module_arguments = "";

my $module_output_to_speak = "";

my @interjection_results = ();
my $interjection_to_respond_to = "";

my @verb_result_string = "";
my $verb_processor_output = "";

if ($initial_run) {
	if ($log_level >= 1) {
		print "Initializing: please wait...\n";
	}
	
	`echo "Initializing: please wait" | festival --tts`;
}

# Here we run the pocketsphinx_continuos command.  It runs as loop.  The thing is we are opening it with the
# "-|", which pipes the output to us.  So essentially we run the command, but we can intercept it's output
# line by line as it is happening.  Note that if you have the volume down to 0 on the mic, this command will
# fail to start.
open ($cmds, "-|", "/usr/local/bin/pocketsphinx_continuous 2> /dev/null");

# As we loop through the output, there is a specific line for each interrupted text, and it starts with a 
# 9 digit number, on colum one.  From there we parse through the text.
while (<$cmds>) {
	if ($initial_run) {
		if ($log_level >= 1) {
			print "Initialization complete.  I am ready for commands.\n\n";
		}
		
		`echo "Initialization complete.  I am ready for commands." | festival --tts`;

		$initial_run = 0;
	}

	chomp ($_);

	if ($_ =~ m/^(\d{9})(: )(.*)/) {
		$command_to_execute = $3;	

		$command_to_execute =~ s/whether/weather/;

		if ($log_level >= 1) {
			print "---------"x10 . "\n";
			print "Phrase detected from microphone...\n";
		}

		if ($log_level >= 5) {
			print "Speech to text received from Pocket Sphinx: $command_to_execute\n";
		}

		# Lets connect to the java socket for opennlp:
		$socket = IO::Socket::INET->new (
						PeerAddr => 'localhost',
						PeerPort => '9999',
						Proto	=> 'tcp',
						Type	=> SOCK_STREAM
						) or print "oops\n";

		# Apparently java wasn't happy with the \n, it wanted the \r to indicate it was the end of the message.
		# Otherwise in.readLine() was hanging waiting for it.
		print $socket "text:$command_to_execute\n\r";

		$pos_tagged_output = <$socket>;

		print "Here is the replay back: $pos_tagged_output";
		
		# Ok, so now that we got the PosTagged version of our voice command, now we need to parse through it.
		@pos_tags = split (' ', $pos_tagged_output);

		foreach $pos_tag (@pos_tags) {
			chomp ($pos_tag);
			
			if ($pos_tag =~ m/(.*)(_)(.*)/) {
				$text = $1;
				$part_of_speech = $3;
				
				# If part of speech is "Noun, singular or mass", or "Noun, plural":
				if ($part_of_speech eq "NN" || $part_of_speech eq "NNS") {
					$sql_query = qq (select * from nouns_and_actions where noun="$text";);
					$sql_query_prepare = $database_handle->prepare ($sql_query);
					$sql_query_return_value = $sql_query_prepare->execute();
					
					if ($sql_query_return_value < 0) {
						print "Error with sql statement: $DBI::errstr";
					}
					
					@noun_row_select_results = $sql_query_prepare->fetchrow_array();
					
					$module_to_run = @noun_row_select_results[1];
					$module_arguments = @noun_row_select_results[2];
					
					if ($module_to_run eq "") {
						print "I didn't find a match for this noun: $text\n";
					}
					
					else {
						print "I am going to run this module: $module_to_run with these arguments: $module_arguments -m $command_to_execute\n";
						
						# um
						$command_to_execute =~ s/ /%20/g;
						
						$module_output_to_speak = `$project_dir/modules/$module_to_run/module_init $module_arguments -m $command_to_execute`;
						chomp ($module_output_to_speak);
						
						print "$module_output_to_speak\n";
						
						`echo $module_output_to_speak | festival --tts`;
					}				
				}
				
				# This is UH, or Interjection:
				elsif ($part_of_speech eq "UH") {
					$sql_query = qq (select * from interjections where word="$text";);
					$sql_query_prepare = $database_handle->prepare ($sql_query);
					$sql_query_return_value = $sql_query_prepare->execute();
					
					if ($sql_query_return_value < 0) {
						print "Error with Interjection sql statement: $DBI::errstr";
					}
					
					@interjection_results = $sql_query_prepare->fetchrow_array();
					
					$interjection_to_respond_to = @interjection_results[0];
					$module_to_run = @interjection_results[1];
					
					if ($interjection_to_respond_to eq "") {
						print "I didn't find a match for this interjection: $text\n";
					}
					
					else {
						print "I am going to run this module: $module_to_run with these arguments: $module_arguments -m $command_to_execute\n";
						
						# um
						$module_output_to_speak = `$project_dir/modules/$module_to_run/module_init $module_arguments -m $interjection_to_respond_to`;
						chomp ($module_output_to_speak);
						
						print "$module_output_to_speak\n";
						
						`echo $module_output_to_speak | festival --tts`;
					}					
				}
				
				# This is VB, or a verb:
				elsif ($part_of_speech eq "VB") {
					$sql_query = qq (select * from verbs where word="$text";);
					$sql_query_prepare = $database_handle->prepare ($sql_query);
					$sql_query_return_value = $sql_query_prepare->execute();
					
					if ($sql_query_return_value < 0) {
						print "Error with verb sql statement: $DBI::errstr";
					}
					
					@verb_result_string = $sql_query_prepare->fetchrow_array();
					
					print "Sending string to verb processor\n";
					$verb_processor_output = `$project_dir/verb_processor.pl -s "@verb_result_string"`;
					
					chomp ($verb_processor_output);
					
					print "Result from verb processor: ***$verb_processor_output***\n";
					`echo $verb_processor_output | festival --tts`;
				}
			}
		}

		close ($socket);

		#*** End new database code here.
	}
}

sub exit_program {
	close ($cmds);
	close (STDOUT);

	
	`echo "Goodbye" | festival --tts`;
}