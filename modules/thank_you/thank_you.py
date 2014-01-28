#!/usr/bin/python

import sys, argparse

parser = argparse.ArgumentParser()

#parser.add_argument ("square", help="display a square of a given number", type=int)
parser.add_argument ("--string_spoken", help="Include the string that was spoken here")

args = parser.parse_args()

if args.string_spoken:
	if args.string_spoken == "thank you":
		print "your welcome"
