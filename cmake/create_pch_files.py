#!/usr/bin/python

import sys

def main():
	# get parameters
	pch_source = sys.argv[1]
	pch_header = sys.argv[2]
	lib_dir = sys.argv[3]
	pch_files = sys.argv[4:]
	
	# create pch.hpp
	pch_hpp = None
	try:
		pch_hpp = open(pch_header, "w")
		for item in pch_files:
			pch_hpp.write("#include \"%s/%s\"\n" % (lib_dir, item))
	finally:
		pch_hpp.close()
	
	# create pch.cpp
	pch_cpp = None
	try:
		pch_cpp = open(pch_source, "w")
		pch_cpp.write("#include \"%s\"" % (pch_header))
	finally:
		pch_cpp.close()

if __name__ == "__main__":
	main()
