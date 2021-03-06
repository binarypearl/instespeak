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
my $opennlp_server;

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
	print "=========="x10 . "\n";
	print "Welcome to instespeak version $version!\n\n";
	print "Date and time: $date_and_time\n";
}

if ($log_level >= 5) {
	print "The current log level is: $log_level\n";
	print "The current project directory is: $project_dir\n";
}

if ($log_level >= 1) {
	print "=========="x10 . "\n\n";
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

my @wrb_results = ();
my $wrb_next_pos = "";
my $wrb_processor = "";

my @verb_result_string = "";
my $verb_processor_output = "";

my $did_i_say_something_flag = 0;

my $opennlp_service_down = 1;
my $opennlp_service_timeout_counter = 0;

my $output = "";

my $opennlp_testing_message = "";

if ($initial_run) {
	if ($log_level >= 1) {
		print "----------"x10 . "\n";
		print "Initializing: please wait...\n";
	}
	
	`echo "Initializing: please wait" | festival --tts`;
}

# Here we run the pocketsphinx_continuos command.  It runs as loop.  The thing is we are opening it with the
# "-|", which pipes the output to us.  So essentially we run the command, but we can intercept it's output
# line by line as it is happening.  Note that if you have the volume down to 0 on the mic, this command will
# fail to start.
open ($cmds, "-|", "/usr/local/bin/pocketsphinx_continuous 2> /dev/null");


# Now let's start the opennlp java server:
open ($opennlp_server, "-|", "cd /mnt/projects/speech/instespeak/PosTagger/bin; java -cp .:\$(echo /mnt/projects/speech/apache-opennlp-1.5.3/lib/*.jar | tr ' ' ':')  PosTagger \"/mnt/projects/speech/apache-opennlp-1.5.3/bin/en-pos-maxent.bin\" 2>&1 /dev/null");
#open ($opennlp_server, "-|", "cd /mnt/projects/speech/instespeak/PosTagger/bin; java -cp .:\$(echo /mnt/projects/speech/apache-opennlp-1.5.3/lib/*.jar | tr ' ' ':')  PosTagger \"/mnt/projects/speech/apache-opennlp-1.5.3/bin/en-pos-maxent.bin\"");

# As we loop through the output, there is a specific line for each interrupted text, and it starts with a 
# 9 digit number, on colum one.  From there we parse through the text.
while (<$cmds>) {
	if ($initial_run) {
		
		while ($opennlp_service_down) {
			#print "D1: opennlp_service_down: ***$opennlp_service_down***\n";
			
			# Let's check to see if port 9999 is up yet:
			# Eventually need to check this better, as 19999 could match as well..etc.
			
			# Lets connect to the java socket for opennlp:
			#$socket = IO::Socket::INET->new (
			#	PeerAddr => 'localhost',
			#	PeerPort => '9999',
			#	Proto	=> 'tcp',
			#	Type	=> SOCK_STREAM
			#	) or print "Socket not up yet\n";
	
			#if ($socket) {	
				#print $socket "testing:are you there?\n\r";
				#$opennlp_testing_message = <$socket>;
				#$opennlp_testing_message = "yes I am";
			
				#if ($opennlp_testing_message =~ m/yes I am/) {
					
			`netstat -taun | grep 9999`;
			
			if (($? >> 8) == 0) {
				$opennlp_service_down = 0;
				
				#print "D2: opennlp_service_down: ***$opennlp_service_down***\n";	
			}
			
			else {
				$opennlp_service_timeout_counter++;
				sleep 1;
				
				if ($opennlp_service_timeout_counter >= 20) {
					exit_program ("error_starting_opennlp");
				}
				
				#print "D3: opennlp_service_down: ***$opennlp_service_down***\n";
				#print "D4: output: ***$output***\n";
			}
			#}
			
			#else {
			#	sleep 1;
			#}
		}
		
		if ($log_level >= 1) {
			print "Initialization complete.  I am ready for commands.\n";
			print "----------"x10 . "\n\n";
		}
		
		# Let's make sure the PosTagger service is running.  Otherwise let's exit, 
		# because we aint do anything else if it's not.
		`echo "Initialization complete.  I am ready for commands." | festival --tts`;

		$initial_run = 0;
	}

	chomp ($_);

	if ($_ =~ m/^(\d{9})(: )(.*)/) {
		$command_to_execute = $3;	

		$command_to_execute =~ s/whether/weather/;

		if ($log_level >= 1) {
			print "----------"x10 . "\n";
			print "Phrase detected: ";
		}

		if ($log_level >= 1) {
			print "$command_to_execute\n";
		}

		# Lets connect to the java socket for opennlp:
		$socket = IO::Socket::INET->new (
			PeerAddr => 'localhost',
			PeerPort => '9999',
			Proto	=> 'tcp',
			Type	=> SOCK_STREAM
			) or print "Socket not up yet\n";

		# Apparently java wasn't happy with the \n, it wanted the \r to indicate it was the end of the message.
		# Otherwise in.readLine() was hanging waiting for it.
		print $socket "text:$command_to_execute\n\r";

		if ($log_level >= 5) {		
			print "Sending \"text:$command_to_execute\" to PosTagger.\n";
		}

		$pos_tagged_output = <$socket>;

		if ($log_level >= 5) {
			print "Reply from PosTagger: $pos_tagged_output";
		}
		
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
						if ($log_level >= 5) {
							print "Error with sql statement: $DBI::errstr";
						}
					}
					
					@noun_row_select_results = $sql_query_prepare->fetchrow_array();
					
					$module_to_run = @noun_row_select_results[1];
					$module_arguments = @noun_row_select_results[2];
					
					if ($module_to_run eq "") {
						if ($log_level >= 5) {
							print "I didn't find a match for this noun: $text\n";
						}
					}
					
					else {
						if ($log_level >= 5) {
							print "Instespeak is going to run this module: \"$module_to_run\" with these arguments: \"$module_arguments -m $command_to_execute\"\n";
						}
						
						# um
						$command_to_execute =~ s/ /%20/g;
						
						$module_output_to_speak = `$project_dir/modules/$module_to_run/module_init $module_arguments -m $command_to_execute`;
						chomp ($module_output_to_speak);
						
						if ($log_level >= 1) {
							print "Instespeak says: $module_output_to_speak\n";
						}
						
						`echo $module_output_to_speak | festival --tts`;
						$did_i_say_something_flag = 1;
					}				
				}
				
				# This is UH, or Interjection:
				elsif ($part_of_speech eq "UH") {
					$sql_query = qq (select * from interjections where word="$text";);
					$sql_query_prepare = $database_handle->prepare ($sql_query);
					$sql_query_return_value = $sql_query_prepare->execute();
					
					if ($sql_query_return_value < 0) {
						if ($log_level >= 1) {
							print "Error with Interjection sql statement: $DBI::errstr";
						}
					}
					
					@interjection_results = $sql_query_prepare->fetchrow_array();
					
					$interjection_to_respond_to = @interjection_results[0];
					$module_to_run = @interjection_results[1];
					
					if ($interjection_to_respond_to eq "") {
						if ($log_level >= 5) {
							print "I didn't find a match for this interjection: $text\n";
						}
					}
					
					else {
						if ($log_level >= 5) {
							print "I am going to run this module: $module_to_run with these arguments: $module_arguments -m $command_to_execute\n";
						}
						
						# um
						$module_output_to_speak = `$project_dir/modules/$module_to_run/module_init $module_arguments -m $interjection_to_respond_to`;
						chomp ($module_output_to_speak);
						
						if ($log_level >= 1) {
							print "Instespeak says: $module_output_to_speak\n";
						}
						
						`echo $module_output_to_speak | festival --tts`;
						$did_i_say_something_flag = 1;
					}					
				}
				
				# This is VB, or a verb:
				elsif ($part_of_speech eq "VB") {
					$sql_query = qq (select * from verbs where word="$text";);
					$sql_query_prepare = $database_handle->prepare ($sql_query);
					$sql_query_return_value = $sql_query_prepare->execute();
					
					if ($sql_query_return_value < 0) {
						if ($log_level >= 1) {
							print "Error with verb sql statement: $DBI::errstr";
						}
					}
					
					@verb_result_string = $sql_query_prepare->fetchrow_array();
					
					if ($log_level >= 5) {
						print "Sending string to verb processor\n";
					}
					
					$verb_processor_output = `$project_dir/verb_processor.pl -s "@verb_result_string"`;
					
					chomp ($verb_processor_output);
					
					if ($log_level >= 1) {
						print "Instespeak says: $verb_processor_output\n";
					}
					
					`echo $verb_processor_output | festival --tts`;
					$did_i_say_something_flag = 1;
				}	# end elsif	

				# This is WRB, or a question word:
				elsif ($part_of_speech eq "WRB") {
					$sql_query = qq (select * from question_words where word="$text";);
					$sql_query_prepare = $database_handle->prepare ($sql_query);
					$sql_query_return_value = $sql_query_prepare->execute();
					
					if ($sql_query_return_value < 0) {
						if ($log_level >= 1) {
							print "Error with WRB sql statement: $DBI::errstr";
						}
					}
					
					# continue on here...
					@wrb_results = $sql_query_prepare->fetchrow_array();
					
					$wrb_next_pos = @wrb_results[1];
					$wrb_processor = @wrb_results[2];							
					
					if ($wrb_next_pos =~ m/VBP/) {
						$verb_processor_output = `$project_dir/verb_processor.pl -s "$command_to_execute"`;
						chomp ($verb_processor_output);
					
						#print "what is: ***$verb_processor_output***\n";
					
						if ($log_level >= 1) {
							print "Instespeak says: $verb_processor_output\n";
						}
					
						`echo "$verb_processor_output" | festival --tts`;
						$did_i_say_something_flag = 1;
					}
				} # end elsif
	
			}	# end if for POS tag
		}	# end foreach
		
		if (! $did_i_say_something_flag) {
			if ($log_level >= 1) {
				print "Instespeak says: Sorry I have nothing to say.\n";
			}
		}

		close ($socket);

		if ($log_level >= 1) {
				print "----------"x10 . "\n\n";
		}

		$did_i_say_something_flag = 0;

		#*** End new database code here.
	}
}

sub exit_program {
	if ($log_level >= 1) {
		print "Goodbye (press ctrl-c if hanging)\n";	
	}

	close ($cmds);
	close (STDOUT);

	if ($_[0] eq "error_starting_opennlp") {
		`echo "Sorry I could not start open n l p" | festival --tts`;
		
		exit 1;	
		exit 1;
	}
	
	else {
		`echo "Goodbye" | festival --tts`;	
		exit 0;
	}
}