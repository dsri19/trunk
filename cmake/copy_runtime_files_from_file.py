#!/usr/bin/python

import sys
import shutil
import os
import filelock
from os.path import getmtime
import time

# Copy source to dest - for each symbolic link the link will be copied as a link and
# the referred file will be copied also
def handle_symlink(source, dest):
    print "Handle symlink(%s, %s)" % (source, dest)
    if os.path.islink(source):
        target = handle_symlink(os.path.join(os.path.split(source)[0], os.readlink(source)), dest)
        link_source = os.path.join(dest, os.path.basename(source))
        print "Create link: %s --> %s" % (link_source, target)
        if not os.path.lexists(link_source):
            os.symlink(target, link_source)
        return os.path.basename(source)
    else:
        shutil.copy2(source, dest)
        return os.path.basename(source)


def getPathComponents(path):
    components = []
    while True:
        (path,tail) = os.path.split(path)
        if tail == "":
            components.reverse()
            return components
        components.append(tail)

def listfiles(path, filter=[".git", ".svn"]):
    """
    http://stackoverflow.com/questions/19251993/comparing-two-directories-with-subdirectories-to-find-any-changes
    """
    files = []
    for dirName, subdirList, fileList in os.walk(path):
        dir = dirName.replace(path, '')

        components = getPathComponents(dir)
        skipDir = False
        for c in components:
            if c in filter:
                skipDir = True
                break
        if not skipDir:
            for fname in fileList:
                if fname not in filter:
                    files.append(os.path.join(dir, fname))
    return files

def main():
    print sys.argv[1:]

    targetdir = sys.argv[1]
    buildtype, outdir = sys.argv[2].split(':')
    files_debug = sys.argv[3]
    files_release = sys.argv[4]
    if len(sys.argv) > 5:
        files_coverage = sys.argv[5]

    outdir = "$(" + outdir + ")"

    files = ""

    if (buildtype.lower() == "debug"):
        files = files_debug
    elif (buildtype.lower() == "'debug'"):
        files = files_debug
    elif (buildtype.lower() == "coverage"):
        files = files_coverage
    elif (buildtype.lower() == "'coverage'"):
        files = files_coverage
    else:
        files = files_release

    # open file and go over all lines
    f = open(files, 'r')

    for line in f:
        line = line.rstrip('\n')

        if line == "":
            continue

        # split list of files by ,
        items = line.split(',')
        extraDir = items[0]
        line = items[1]

        line = line.replace(outdir, buildtype)
        dir = "%s" % (targetdir)
        if (extraDir != "" and extraDir != "."):
            dir += "/%s" % (extraDir)

        dir = dir.replace(outdir, buildtype)

        newfile = dir + "/" + os.path.basename(line)

        #only copy the file if its not the same name and if creation time of the file to copy is newer

        lock = None
        try:
            if not os.path.exists(dir):
                try:
                    os.makedirs(dir)
                except OSError:
                    pass

            lock = filelock.FileLock(newfile, timeout=600, delay=1.0)
            lock.acquire()

            new_mtime = 0
            try:
                new_mtime = getmtime(newfile)
            except:
                pass

            if os.path.exists(line):
                filesOnlyInSource = []
                directoriesEqual = True
                isDirectory = os.path.isdir(line)
                if ( isDirectory ):
                    sourceFiles = listfiles(line)

                    targetFiles = listfiles(newfile)

                    filesOnlyInSource = set(sourceFiles) - set(targetFiles)

                    if ( len(filesOnlyInSource) > 0 ):
                        directoriesEqual = False


                # due to problems with accuracy we compare with epsilon 
                timeDiff = abs(getmtime(line) - new_mtime);
                epsilon = 0.0001
                if ( (newfile != line) and ( timeDiff > epsilon ) or not directoriesEqual ):

                    try:
                        print "Copy %s to %s" % (line, dir)

                        # print "directories equal: " + str(directoriesEqual)
                        # print filesOnlyInSource
                        # print "source: " + line + " -> mtime: " + str(round(getmtime(line),2)) + " " + time.ctime(getmtime(line))
                        # print "newfile: " + newfile + " -> mtime: " + str(round(new_mtime,2)) + " " + time.ctime(new_mtime)

                        if (isDirectory):
                            # - copytree requires that the target directory does not exist yet
                            target_directory = os.path.join(dir, os.path.basename(line))
                            if (os.path.isdir(target_directory)):
                                shutil.rmtree(target_directory)
                            shutil.copytree(line, target_directory, ignore=shutil.ignore_patterns('.git','.svn'))
                        else:
                            handle_symlink(line, dir)
                    except shutil.Error as e:
                        print "ERROR: ", e
                        pass
            else:
                # File does not exist - this is not an error for PDB files so far
                (filename, extension) = os.path.splitext(line)
                if extension != ".pdb":
                    raise Exception("File %s not found" % (line))

        except filelock.FileLockException:
            print "Failed to acquire " + newfile + ".lock"
            print "There could be a .lock file already present in the folder."
            sys.exit(-1)
        finally:
            if lock:
                lock.release()


if __name__ == "__main__":
    main()
