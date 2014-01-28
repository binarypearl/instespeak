#!/usr/bin/perl

use strict;

use Getopt::Long;

use Glib qw/TRUE FALSE/;
use Gtk2 '-init';
use Gnome2::Wnck;

my $screen = "";
my $active_window = "";

my $pid = "";

my $message_from_main = "";

GetOptions (
	"message:s" => \$message_from_main,
);

chomp ($message_from_main);

$message_from_main =~ s/%20/ /;

if ($message_from_main =~ m/term/) {
	`/usr/bin/gnome-terminal`;
	
	print "Terminal launched.\n";
}

elsif ($message_from_main =~ m/internet/) {
	$pid = fork();
	
	if ($pid == 0) {
		`/usr/bin/google-chrome &`;	
		print "Chrome launched\n";
	}
}

elsif ($message_from_main =~ m/close/) {
	$screen = Gnome2::Wnck::Screen -> get_default();
	$screen -> force_update();
	$active_window = $screen->get_active_window();
					
	#print "AW: " . $active_window->get_name() . "\n";
	
	$active_window->close($active_window);
	print "Closing window.\n";
}
					

