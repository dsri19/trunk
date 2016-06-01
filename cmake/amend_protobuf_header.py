#!/usr/bin/python

import sys
import os
import random
import re

def main():
	if (len(sys.argv) < 3):
		sys.stderr.write("Usage: %s <PROTOFILE> <INCLUDE>" % sys.argv[0])
		sys.exit(1)

	filename = ""
	if (len(sys.argv) == 2):
		filename = sys.argv[1]
	else:
		sys.path.append(sys.argv[1])
		filename = sys.argv[1]
	
	includestring = sys.argv[2]
		
	infile = open(filename, 'rb')
	print "amending " + filename + " with " + includestring
	included = False;
	
	tmpfilename = filename + "." + str(random.randrange(0, 1024))
	outfile = open(tmpfilename, 'w')
	
	pattern = re.compile("^#define .*")
	
	included = False
    	
	try:
		for line in infile:	
			if pattern.match(line) and not included:
				outfile.write(line)
				outfile.write("#include \"%s\"\n" % includestring)
				included = True
			else:
				outfile.write(line)
	finally:
		infile.close()
		outfile.close()
		
	print "amending done, moving file in place"
	os.remove(filename)
	os.rename(tmpfilename, filename)
	
	exit(0)

if __name__ == "__main__":
	main()
