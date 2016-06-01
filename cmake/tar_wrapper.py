import os
import sys
import tarfile

def tardir(source_directory, target_file=None, include_top_level_directory_in_archive=True):
    print("Taring %s to %s." % (source_directory, target_file))
    if not os.path.isdir(source_directory):
        raise OSError("Invalid source directory %s." % source_directory)
    with tarfile.open(target_file, "w:gz", compresslevel=5) as tar:
        if(include_top_level_directory_in_archive):
            tar.add(source_directory)
        else:
            for (dirpath, dirnames, filenames) in os.walk(source_directory):
                for f in filenames:
                    relpath = os.path.relpath(dirpath, source_directory)
                    if (relpath == "."):
                        relpath = ""
                    tar.add(os.path.join(dirpath, f), os.path.join(relpath, f))

def any_file_newer_than(source_directory, ref_date):
    for (dirpath, dirnames, filenames) in os.walk(source_directory):
        print "Checking %s" % dirpath
        for f in filenames:
            if os.stat(os.path.join(dirpath, f)).st_mtime > ref_date:
                print "File change for %s" % f
                return True
    return False    

target_file = sys.argv[1]
dirs = sys.argv[2:]

# the tar file is only generated if at least one file in the source directory
# has a newer modification date than the target file
needs_update = not os.path.isfile(target_file)
for dir in dirs:
    if needs_update:
        break
    needs_update = any_file_newer_than(dir, os.stat(target_file).st_mtime)

if needs_update:
    for dir in dirs:
        try:
            tardir(dir, target_file, False)
        except:
            if(os.path.isfile(target_file)):
                os.remove(target_file)
            raise
else:
    print "Archive %s is up-to-date." % target_file
