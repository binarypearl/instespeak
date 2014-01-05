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

my $cmds;

my $command_to_execute = "";

my $screen = "";
my $active_window = "";

my $pid = "";

my $initial_run = 1;

my $weather_temperature = "";
my $previous_command = "";

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
		#print "***$3***\n";

		$command_to_execute = $3;	

		print "***The command that I got was: $command_to_execute***\n";
		#`echo "$command_to_execute" | festival --tts`;

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
				$weather_temperature = `weather -i KUGN -a -z il/ILZ006 -s il -c Waukegan | grep "Temperature:" | tr -s ' ' | cut -d ' ' -f3`;
				print "The current temperature is: $weather_temperature\n";
				`echo "The current temperature is: $weather_temperature degrees\n" | festival --tts`;
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

