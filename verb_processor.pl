#!/usr/bin/perl

use strict;

use Getopt::Long;

my $project_directory = "/mnt/projects/speech/instespeak";

my $database_string_to_parse = "";

my $word = "";
my $pos_that_takes_action = "";
my $subject_taking_action = "";

my $string_to_pass = "";
my $text_to_speak = "";

GetOptions (
	"string:s" => \$database_string_to_parse,
);

chomp ($database_string_to_parse);

if ($database_string_to_parse =~ m/(.*)(\s)(.*)(\s)(.*)/) {
	$word = $1;
	$pos_that_takes_action = $3;
	$subject_taking_action = $5;
}

#print "word: ***$word***\n";
#print "pos:  ***$pos_that_takes_action***\n";
#print "sub:  ***$subject_taking_action***\n";


# What we are going to do here is try to make it so instespeak realizes that it's
# being talked to.
	
if ($subject_taking_action =~ m/you/) {
	if ($pos_that_takes_action =~ m/are/) {
		$text_to_speak = `$project_directory/modules/computer_health/module_init`;
	}	
}

# This else is just to house the original code.
else {
	# screw making it more complicated, lets just pass the thank you string to be spoken for now.
	$string_to_pass = $word . " " . $subject_taking_action; 
	#print "string to pass is: $string_to_pass\n";

	$text_to_speak = `$project_directory/modules/thank_you/thank_you.py --string_spoken "$string_to_pass"`;

	# No newline here, it was adding too many of them.
}

print "$text_to_speak";
