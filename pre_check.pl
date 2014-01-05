#!/usr/bin/perl

use strict;

# we need to check for:
# 1. festival
# 2. pocketsphinx_continuous
# 3. perl lib's glib, gtk, wnck
# 4. weather-util
# 5. sqlite

my @status_records = ();
my $status_record = "";

# Checking for Festival:
`festival -v`;
if (($? >> 8) == 0) {
	push (@status_records, "festival:\t\t\t\tOK");
}

else {
	push (@status_records, "festival:\t\tFAIL");
}


# Checking for pocketsphinx_continuous:
# This is rather ugly, but there doesn't seem to be a way to get any info and exit,
# so we give it a bad command line option.  That will force it to return 1,
# as compared to 127 if the command was not found.  The reason for this is,
# if you happen to find the command and run, you would start the 
# pocketsphinx_continuous loop, and we don't want that here.
`pocketsphinx_continuous -badoption 2> /dev/null`;
if (($? >> 8) == 1) {
	push (@status_records, "pocketsphinx_continuous:\t\tOK");
}

else {
	push (@status_records, "pocketsphinx_continuous:\t\tFAIL");
}


# Checking for perl modules:

print "Please make sure all entries below say \"OK\" before proceeding:\n";

foreach $status_record (@status_records) {
	chomp ($status_record);

	print $status_record . "\n";
}
