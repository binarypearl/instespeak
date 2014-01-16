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

my $project_dir = "/mnt/projects/speech/apache-opennlp-1.5.3/";

my $socket = "";
my $pos_tagged_output = "";

my @pos_tags = ();
my $pos_tag = "";

my $text = "";
my $part_of_speech = "";

my $dbfile = "/mnt/projects/speech/instespeak/instespeak.db";


system ("clear");

if ($initial_run) {
	print "Initializing: please wait...\n";
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
		print "Initialization complete.\n";
		`echo "Initialization complete.  I am ready for commands." | festival --tts`;

		$initial_run = 0;
	}

	chomp ($_);

	if ($_ =~ m/^(\d{9})(: )(.*)/) {
		$command_to_execute = $3;	

		$command_to_execute =~ s/whether/weather/;

		print "***The command that I got was: $command_to_execute***\n";
		#`echo "$command_to_execute" | festival --tts`;

		#*** New database code here:

		# So first, we need to pass the text to OpenNLP, so we tag the words with the different parts of speech.
		#@opennlp_output = `echo $command_to_execute | $project_dir/bin/opennlp POSTagger $project_dir/bin/en-pos-maxent.bin`;

		#foreach $opennlp_record (@opennlp_output) {
		#	chomp ($opennlp_record);
                # 
		#	print $opennlp_record . "\n";
		#}

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
				
				if ($part_of_speech eq "NN") {
					#
					
				}
			}
		}

		close ($socket);

		#*** End new database code here.

		if ($command_to_execute =~ m/^computer$/) {
			`echo "What can I do for you?" | festival --tts`;
		}

		if ($command_to_execute =~ m/computer/) {
			if ($command_to_execute =~ m/new/) {
				if ($command_to_execute =~ m/term/) {
					`/usr/bin/gnome-terminal`;	
					`echo "$command_to_execute launched" | festival --tts`;
				}

				elsif ($command_to_execute =~ m/internet/) {
					$pid = fork();

					if ($pid == 0) {
						`/usr/bin/google-chrome &`;	
						`echo "$command_to_execute launched" | festival --tts`;
					}
				}
			}

			elsif ($command_to_execute =~ m/close/) {
				# Sphinx often thinks 'with no' is 'window', allowing for both
				if ($command_to_execute =~ m/window/ || $command_to_execute =~ m/with no/) {
					$screen = Gnome2::Wnck::Screen -> get_default();
					$screen -> force_update();
					$active_window = $screen->get_active_window();
					
					print "AW: " . $active_window->get_name() . "\n";
	
					$active_window->close($active_window);
					`echo "Closing window." | festival --tts`;
				}
			}

		}

		elsif ($command_to_execute =~ m/weather/ || $command_to_execute =~ m/whether/) {
			if ($command_to_execute =~ m/temperature/) {
				#$weather_temperature = `weather -i KUGN -a -z il/ILZ006 -s il -c Waukegan | grep "Temperature:" | tr -s ' ' | cut -d ' ' -f3`;
				@weather_report_output_records = `weather -i KUGN -s il -c Waukegan -v`; 
		
				foreach $weather_report_record (@weather_report_output_records) {
					chomp ($weather_report_record);

					if ($weather_report_record =~ m/(^Temperature: )(.*)( F)(.*)/) {
						$weather_temperature = $2;
					} 

					elsif ($weather_report_record =~ m/(^Windchill: )(.*)( F)(.*)/) {
						$weather_windchill = $2;
					}
				}

				print "The current temperature is $weather_temperature degrees and the windchill is $weather_windchill degrees\n";
				`echo "The current temperature is $weather_temperature degrees and the windchill is $weather_windchill degrees\n" | festival --tts`;
			}
		}

		elsif ($command_to_execute =~ m/previous command/) {
			print "The previous command was: ***$previous_command***\n";
			`echo "$previous_command" | festival --tts`;
		}

		$previous_command = $command_to_execute;
	}
}

close $cmds;

