#!/usr/bin/perl

use strict;

use Getopt::Long;

# Just a comment
# C2
# C3

my @weather_report_output_records = ();
my $weather_report_record = "";
my $weather_temperature = "";
my $weather_windchill = "";

my $version_flag = "";
my $version = "0.01";

my $temperature_flag = "";

my $text_to_speak = "";

my $weather_wind_direction = "";
my $weather_wind_speed = "";
my $weather_wind_speed_units = "";

my $sky_conditions = "";

my $message_from_main = "";

GetOptions (
	"version" => \$version_flag,
	"temperature" => \$temperature_flag,
	"message:s" => \$message_from_main,
);

if ($version_flag) {
	print "Version is: $version\n";
}

#if ($temperature_flag) {
#	print "Temperature flag here also\n";
#}

@weather_report_output_records = `weather -i KUGN -s il -c Waukegan -v`;				

# If just temperature is requested, lets say the temperature and the windchill
if ($temperature_flag) {				
	foreach $weather_report_record (@weather_report_output_records) {
		chomp ($weather_report_record);

		if ($weather_report_record =~ m/(^Temperature: )(.*)( F)(.*)/) {
			$weather_temperature = $2;
		} 

		elsif ($weather_report_record =~ m/(^Windchill: )(.*)( F)(.*)/) {
			$weather_windchill = $2;
		}
	}
	
	$text_to_speak = "The current temperature is $weather_temperature degrees and the windchill is $weather_windchill degrees\n";
}

# If we want just general weather, lets parse out some of the more interesting facts from noaa:
else {
	foreach $weather_report_record (@weather_report_output_records) {
		chomp ($weather_report_record);
	
		# The current skys are $sky_conditions with a temperature of $weather_temperature degrees and a windchill of $weather_windchill.
		# The winds are $wind mph from a $variable/n/s/e/w direction.
	
		if ($weather_report_record =~ m/^(Wind:)(\s)(.*)(\s)(.*)(\s)(.*)(\s)(.*)(\s)(.*)/) {
			$weather_wind_direction = $3;
			$weather_wind_speed = $5;
			$weather_wind_speed_units = $7;
		}
	
		elsif ($weather_report_record =~ m/^(Sky conditions: )(.*)/) {
			$sky_conditions = $2;
		}
	
		elsif ($weather_report_record =~ m/(^Temperature: )(.*)( F)(.*)/) {
			$weather_temperature = $2;
		} 

		elsif ($weather_report_record =~ m/(^Windchill: )(.*)( F)(.*)/) {
			$weather_windchill = $2;
		}
	}
	
	$text_to_speak = "The current skys are $sky_conditions with a temperature of $weather_temperature degrees and a windchill of $weather_windchill degrees.\n";
}


print $text_to_speak;

