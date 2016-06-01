#!/usr/bin/python

import sys
import shutil
import os
import filelock

def main():
    print sys.argv[1:]

    targetdir = sys.argv[1]
    buildtype = sys.argv[2]
    files_debug = sys.argv[3]
    files_release = sys.argv[4]

    files = ""

    if (buildtype.lower() == "debug"):
        files = files_debug
    elif (buildtype.lower() == "'debug'"):
        files = files_debug
    else:
        files = files_release

    # split list of files by ;
    items = files.split(',')

    for i in range (0, items.__len__() / 2):
        dir = "%s/%s" % (targetdir, items[2*i])
        try:
            os.makedirs(dir)
        except OSError:
            pass

        lock = None
        try:
            lock = filelock.FileLock(dir + "/" + os.path.basename(items[2*i+1]), timeout=5, delay=0.5)
            lock.acquire()
            shutil.copy2(items[2*i+1], dir)
        except filelock.FileLockException:
            print "Failed to acquire file lock - timeout"
            shutil.copy2(items[2*i+1], dir)
        except shutil.Error:
            pass
        finally:
            if lock:
                lock.release()

if __name__ == "__main__":
    main()
