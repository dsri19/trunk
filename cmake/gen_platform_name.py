import sys
import os

PLATFORM = sys.argv[1]
PLATFORM_FILE = "platform.nsh"
CONTENT = "!define PLATFORM %s"

def open_file_for_writting(filename):
    "return a handle to the file to write to"
    try:
        h = file(filename, "w")
    except:
        print "Problem opening file %s for writting" % filename
        print __doc__
        sys.exit(1)
    return h

platform_name_file_handle = open_file_for_writting(PLATFORM_FILE)
print >> platform_name_file_handle, CONTENT % PLATFORM
platform_name_file_handle.close()
