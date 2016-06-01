import sys, os, glob

# Define input directory and names of output files
SOURCE_DIR = sys.argv[1]
INST_LIST = "install_list.nsh"
UNINST_LIST = "uninstall_list.nsh"
MD5_LIST = "md5_list.nsh"

# Define Templates for the output files
INST_DIR_TPL  = '  SetOutPath "$INSTDIR%s"'
UNINST_DIR_TPL  = '  RMDir "$INSTDIR%s"'
INST_FILE_TPL = '  File "%s%s"' % (SOURCE_DIR, "%s")
UNINST_FILE_TPL = '  Delete "$INSTDIR%s"'
MD5_FILE_TPL = '  !insertmacro AddMD5 "$INSTDIR%s" "%s"'

def open_file_for_writting(filename):
    "return a handle to the file to write to"
    try:
        h = file(filename, "w")
    except:
        print "Problem opening file %s for writting" % filename
        print __doc__
        sys.exit(1)
    return h


inst_file_handle = open_file_for_writting(INST_LIST)
uninst_file_handle = open_file_for_writting(UNINST_LIST)
md5_file_handle = open_file_for_writting(MD5_LIST)

stack_of_visited = []
counter_files = 0
counter_dirs = 0
print "Generating the install & uninstall list for directory %s" % SOURCE_DIR
print >> inst_file_handle,  "  ; Files to install\n"
print >> uninst_file_handle,  "  ; Files and dirs to remove\n"
print >> md5_file_handle, "  ; MD5 hash calculation\n"

def my_visitor(my_stack, cur_dir, files_and_dirs):
    "add files to the install list and accumulate files for the uninstall list"
    global counter_dirs, counter_files, stack_of_visited
    counter_dirs += 1

    # first separate files
    my_files = [x for x in files_and_dirs if os.path.isfile(cur_dir + os.sep + x) and x[-3:] != 'pdb']
    # and truncate dir name
    my_dir = cur_dir[len(SOURCE_DIR):]
    if my_dir == "":
        my_dir = "\\."

    # save it for uninstall
    stack_of_visited.append( (my_files, my_dir) )

    # build install list
    if len(my_files):
        print >> inst_file_handle,  INST_DIR_TPL % my_dir

        for f in my_files:
            print >> inst_file_handle,  INST_FILE_TPL % (my_dir + os.sep + f)

            # Short name: path relative to powerhouse_home, thus "\" stripped
            shortname = my_dir[1:] + os.sep + f
            print >> md5_file_handle, MD5_FILE_TPL % (my_dir + os.sep + f, shortname)
            counter_files += 1

        print >> inst_file_handle, "  "
        print >> md5_file_handle, "  "

os.path.walk( SOURCE_DIR, my_visitor,  stack_of_visited)
inst_file_handle.close()
md5_file_handle.close()
print "Install list done"
print "  ", counter_files, "files in", counter_dirs, "dirs"

stack_of_visited.reverse()

# Manually add htdocs/md5.txt to uninstall list
print >> uninst_file_handle, UNINST_FILE_TPL % "\\htdocs\\md5.txt"

# Manually add etc/filestore.pem to uninstall list
print >> uninst_file_handle, UNINST_FILE_TPL % "\\etc\\filestore.pem"

print >> uninst_file_handle, "  "

# Now build the uninstall list
for (my_files, my_dir) in stack_of_visited:
        for f in my_files:
            print >> uninst_file_handle,  UNINST_FILE_TPL % (my_dir + os.sep + f)
        print >> uninst_file_handle, UNINST_DIR_TPL % my_dir
        print >> uninst_file_handle, "  "

# now close everything
uninst_file_handle.close()
print "Uninstall list done. Got to end.\n"
