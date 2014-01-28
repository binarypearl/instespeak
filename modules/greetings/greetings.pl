#!/usr/bin/perl

use strict;

use Getopt::Long;

my $message_from_main = "";

GetOptions (
	"message:s" => \$message_from_main,
);

if ($message_from_main =~ m/hello/) {
	print "Hello there.  How is life?\n";
}

elsif ($message_from_main =~ m/computer/) {
	print "What can I do for you?\n";
}

