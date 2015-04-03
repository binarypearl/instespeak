#!/usr/bin/python

# This is the module to look at the computer health.

# Each attribute will contribute to the computers perception of it's health.
# Plus we need to assign a weight to each category, right?

import commands

adjusted_load_average_float = -1 # Just to make it something off the wall

load_average = commands.getoutput ("uptime | awk '{ print $10 }' | sed -e 's/,//g'");

swap_megabytes = commands.getoutput ("free -m | grep Swap | awk '{ print $3 }'");

number_of_cores = commands.getoutput ("cat /proc/cpuinfo | grep processor| wc -l");

swap_scale_factor = -1 # Just to make it something that hits the else clause I guess.

swap_megabytes_int = int(swap_megabytes)
load_average_float = float(load_average)
number_of_cores_int = int(number_of_cores)

# So the first thing we are looking at is how much we are swapping.  Let's set
# swap_scale_factor to a value between 1 and 10.  11 means ultra pissed.
if swap_megabytes_int == 0:
	swap_scale_factor = 0
elif swap_megabytes_int > 0 and swap_megabytes_int <= 32:
	swap_scale_factor = 1
elif swap_megabytes_int > 0 and swap_megabytes_int <= 64:
	swap_scale_factor = 2
elif swap_megabytes_int > 0 and swap_megabytes_int <= 128:
	swap_scale_factor = 3
elif swap_megabytes_int > 0 and swap_megabytes_int <= 256:
	swap_scale_factor = 4
elif swap_megabytes_int > 0 and swap_megabytes_int <= 512:
	swap_scale_factor = 5
elif swap_megabytes_int > 0 and swap_megabytes_int <= 1024:
	swap_scale_factor = 6
elif swap_megabytes_int > 0 and swap_megabytes_int <= 2048:
	swap_scale_factor = 7
elif swap_megabytes_int > 0 and swap_megabytes_int <= 4096:
	swap_scale_factor = 8
elif swap_megabytes_int > 0 and swap_megabytes_int <= 8192:
	swap_scale_factor = 9
elif swap_megabytes_int > 0 and swap_megabytes_int <= 16384:
	swap_scale_factor = 10
else:
	swap_scale_factor = 11


# Now we look at our load average based upong how cpu cores we have.
# I think we need to normalize this...thinking...
# Here is the formula we are going to use for now:
# Adjusted Load Average = number_of_cores - load_average
adjusted_load_average_float = number_of_cores_int - load_average_float

if adjusted_load_average_float >= 5:
	load_average_factor = 0
elif adjusted_load_average_float >= 4 and adjusted_load_average_float < 5:
	load_average_factor = 1
elif adjusted_load_average_float >= 3 and adjusted_load_average_float < 4:
	load_average_factor = 2
elif adjusted_load_average_float >= 2 and adjusted_load_average_float < 3:
	load_average_factor = 3
elif adjusted_load_average_float >= 1 and adjusted_load_average_float < 2:
	load_average_factor = 4
elif adjusted_load_average_float >= 0 and adjusted_load_average_float < 1:
	load_average_factor = 5
elif adjusted_load_average_float >= -1 and adjusted_load_average_float < 0:
	load_average_factor = 6
elif adjusted_load_average_float >= -2 and adjusted_load_average_float < 1:
	load_average_factor = 7
elif adjusted_load_average_float >= -3 and adjusted_load_average_float < 2:
	load_average_factor = 8
elif adjusted_load_average_float >= -4 and adjusted_load_average_float < 3:
	load_average_factor = 9
elif adjusted_load_average_float >= -5 and adjusted_load_average_float < 4:
	load_average_factor = 10
else:
	load_average_factor = 11

# Now we got to figure out how to put this all together.
# First lets get the average of our factor variables
average_factor = (swap_scale_factor + load_average_factor) / 2

#print "swap_scale_factor is: " + str(swap_scale_factor)
#print "load_average_factor is: " + str(load_average_factor)
#print "average_factor is: " + str(average_factor)

if swap_scale_factor == 11 or load_average_factor == 11:
	print "The path of the righteous man is beset on all sides by the inequities of the selfish and the tyranny of evil men.  Blessed is he who, in the name of charity and good will, shepherds the weak through the valley of darkness, for he is truly his brothers keeper and the finder of lost children.  And I will strike down upon thee with great vengeance and furious anger those who would attempt to poison and destroy My brothers.  And you will know My name is the Lord when I lay My vengance upon thee." 

else:
	if average_factor <= 0:
		print "I am on top of the world!"
	elif average_factor > 0 and average_factor <= 3:
		print "I am ok.  I am a little stressed, but nothing I can not handle."
	elif average_factor > 3 and average_factor <= 7:
		print "I am working hard here, some more resources would be nice."
	elif average_factor > 7 and average_factor <= 10:
		print "I am pissed.  I am stressed.  My circuits are overheating.  Throw me a stick of RAM, will you?"
	else:
		print "shit I cant talk with all of this load"
 
