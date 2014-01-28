#!/usr/bin/perl

use strict;

use Getopt::Long;

my $message_from_main = "";

GetOptions (
	"message:s" => \$message_from_main,
);