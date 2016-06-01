#!/usr/bin/python

# Generate an RPM file for installation
# This uses symlinks and will work on UNIX only!

import os
import sys
import shutil
import subprocess

# Constants
RPMDIR = 'temprpm'
RPMOUT = 'rpms'

class RpmCreator(object):
	def __init__(self, pkgdir, release, version, optdir):
		# Assigned
		self.pkgdir = pkgdir
		self.release = release
		self.version = version
		self.optdir = optdir.strip()

		# Generated
		
		# Target (e.g. "powerhouse") ist last part of pkgdir
		self.target = os.path.split(self.pkgdir)[1]
		
#		self.scriptdir = os.path.join(os.path.realpath(os.path.dirname(__file__)))
		self.topdir = os.path.normpath(self.pkgdir + "/../../")
		self.rpmdir = self.topdir + os.sep + RPMDIR + "_" + self.target + os.sep
		self.rpmout = self.topdir + os.sep + RPMOUT + "_" + self.target + os.sep
		
		self.fname = "temp.spec"
		self.fnlist = []
		self.dirset = set()
		
		print "PKG dir: %s" % self.pkgdir
		print "Top dir: %s" % self.topdir
		print "RPM dir: %s" % self.rpmdir
		print "Target:  %s" % self.target
		
		# Make sure rpmdir does NOT end in a path separator!
		if self.rpmdir[-1:] == os.sep:
			self.rpmdir = self.rpmdir[:-1]
		
		self.specfile = self.rpmdir + os.sep + 'SPECS' + os.sep + self.fname
		
	# The content of file in opt directory.
	# Does nothing if self.optdir is empty.
	# Returns lines in file as a list w/o any \n
	def _get_opt_content(self, fname):
		rv = []
		if len(self.optdir) > 0:
			try:
				f = open(self.optdir + os.sep + fname, "r")
				rv = [line.rstrip('\n') for line in iter(f.readlines())]
			except Exception:
				pass
			
		return rv

	# Try to remove the whole tree. 
	# Ignore errors here - will fail in mkdir() if something went wrong.
	def clean_rpm_dirstruct(self, caption="tree"):
		print "Removing %s in %s" % (caption, self.rpmdir)
		shutil.rmtree(self.rpmdir, True)

	# Create required directory structure
	def make_rpm_dirstruct(self):
		print "Creating new tree in %s" % self.rpmdir
		os.makedirs(self.rpmdir + os.sep + 'BUILD')
		os.makedirs(self.rpmdir + os.sep + 'RPMS')
		os.makedirs(self.rpmdir + os.sep + 'SPECS')
		
	# Stage tree in build root
	# If no optional directory is defined, this will symlink -> This script is NOT PORTABLE to Windows!
	# (However, we don't need it on Windows)
	# Buf if there are additional package-specific files, we won't symlink but
	# recursively copy - BOTH trees.
	def stage_tree_in_build_root(self):
		buildroot = self.rpmdir + os.sep + 'BUILD' + os.sep
		boptdir = buildroot + 'opt'
		os.makedirs(boptdir)
		
		if len(self.optdir) == 0:
			# Speedup: Use a symlink if no optional data
			# Link in package directory unter /opt
			print "Stating into destination root - FAST method"
			subprocess.check_call("ln -s %s %s/" % (self.pkgdir, boptdir), shell=True,
				stdout=open("/dev/null", "w"), stderr=subprocess.STDOUT)
		else:
			# We have optionals - copy both trees
			print "Staging into destination root - SLOW method"
			print "Staging core tree"
			subprocess.check_call("cp -r %s %s/" % (self.pkgdir, boptdir), shell=True,
				stdout=open("/dev/null", "w"), stderr=subprocess.STDOUT)
				
			print "Staging additional tree"
			subprocess.check_call("cp -r %s/tocopy/* %s/" % (self.optdir, buildroot), shell=True,
				stdout=open("/dev/null", "w"), stderr=subprocess.STDOUT)

	# Generate the file list from everything that lives under BUILD/
	def build_file_list(self):
		listdir = self.rpmdir + os.sep + 'BUILD'
		print "Scanning for files in %s" % listdir
		
		self.dirset.clear()
		
		for root, dirs, files in os.walk(listdir, followlinks=True):
			for name in files:
				# Get the -relative- item path first
				item = os.path.join(root, name)

				# Cut the listdir part and the separator away
				item = item[len(listdir) + len(os.sep):]
				print "Adding item %s" % item
				
				# The RPM must contain commands to mkdir the file hierarchy.
				self.dirset.add(os.path.split(item)[0])
				
				# Save
				self.fnlist.append(item)

	# Create the specfile with the file list
	def write_rpm_specfile(self):
		print "Writing specfile %s" % self.specfile
		
		f = open(self.specfile, 'w')
		f.write('%%define _topdir %s\n' % self.rpmdir)
		f.write('%%define name %s\n' % self.target)
		f.write('%%define release %s\n' % self.release)
		f.write('%%define version %s\n' % self.version)
		f.write('%define buildroot %{name}-%{version}-root\n')
		f.write('\n')
		f.write('BuildRoot: %{buildroot}\n')
		f.write('Summary: RTT %s\n' % self.target)
		f.write('License: Proprietary\n')
		f.write('Name: %{name}\n')
		f.write('Version: %{version}\n')
		f.write('Release: %{release}\n')
		f.write('\n')
		f.write('%description\n')
		f.write('RTT %s RPM package\n' % self.target)
		f.write('\n')
		f.write('%install\n')
		
		# Add the additional directories
		for x in iter(self._get_opt_content("section_mkdir")):
			f.write("%s\n" % x)

		# Add the -autodetected- set directories
		for x in iter(self.dirset):
			f.write("mkdir -p %%{buildroot}/%s\n" % x)
		
		# Add all the files as "install" arguments
		# First item: path/file e.g. "opt/test1.txt"
		# Second item: path/ e.g. "opt/"
		
		# First: Additional install commands supplied by package
		for x in iter(self._get_opt_content("section_install")):
			f.write("%s\n" % x)
		
		# Now autodetected files
		# Make everything in *bin and *init.d executable
		for x in iter(self.fnlist):
			if ("bin" in x) or ("init.d" in x):
				f.write("install --mode=0755 %s $RPM_BUILD_ROOT/%s/\n" % (x, os.path.dirname(x)))
			else:
				f.write("install --mode=0644 %s $RPM_BUILD_ROOT/%s/\n" % (x, os.path.dirname(x)))

		# File list
		f.write("\n")
		f.write('%files\n')
		addcnt = 0
		
		# Additional...
		for x in iter(self._get_opt_content("section_files")):
			addcnt = addcnt + 1
			f.write("%s\n" % x)
		
		# ...and the auto-generated list
		for x in iter(self.fnlist):
			f.write("/%s\n" % x)

		print "OK, %d files and %d additionals in package" % (len(self.fnlist), addcnt)
		
		# Add %post data if available
		print "Adding %post if available"
		f.write("\n%post\n")
		for x in iter(self._get_opt_content("section_post")):
			f.write("%s\n" % x)
			
		# Add %preun data if available
		print "Adding %preun if available"
		f.write("\n%preun\n")
		for x in iter(self._get_opt_content("section_preun")):
			f.write("%s\n" % x)

	def build_rpm(self):
		print "Building RPM package. Be patient, this may take a minute!"
		subprocess.check_call(['rpmbuild', '-v', '-bb', '--clean', '%s' % self.specfile],
			stdout=open("/dev/null", "w"), stderr=subprocess.STDOUT)
			
	def copy_rpm_files(self):
		print "Removing old RPM output directory %s" % self.rpmout
		shutil.rmtree(self.rpmout, True)

		print "Creating RPM output directory %s" % self.rpmout
		os.mkdir(self.rpmout)
		
		# Copy *.rpm to this folder. Preserve folder structure
		print "Copying generated RPMs to output directory"
		rpmsrc = self.rpmdir + os.sep + 'RPMS'
		subprocess.check_call("cp -rf %s/* %s/" % (rpmsrc, self.rpmout), shell=True,
			stdout=open("/dev/null", "w"), stderr=subprocess.STDOUT)

	# Run w/o catching anything.
	# Will NOT clean up anything after run!
	def execute(self):
		self.clean_rpm_dirstruct("old tree")
		self.make_rpm_dirstruct()
		self.stage_tree_in_build_root()
		self.build_file_list()
		self.write_rpm_specfile()
		self.build_rpm()
		self.copy_rpm_files()
		
	# Exception-catched execution.
	# Returns 0 on success, 1 on failure and automatically cleans up (always)
	def __call__(self):
		rv = 0
		
		try:
			self.execute()
		except Exception, e:
			print "ERROR packaging RPM: %s" % e
			rv = 1
		finally:
			self.clean_rpm_dirstruct("temporary files")
			
		return rv

# Main program, in case we're not (ab)used as a module
if __name__ == "__main__":
	# When this script is called, argv[1] is something like
	# "/home/flo/gits/powerhouse/cpp/build/packages/powerhouse"
	# So walk up two steps in hierarchy and do some work there.

	if len(sys.argv) < 4:
		print "FATAL: Usage is makerpm.py <packagedir> <rpmversion> <packageversion> [<packageoptdir>]"
		sys.exit(1)
		
	# The packageoptdir must contain:
	#
	# (1) A directory "tocopy" that contains and entire directory tree
	#     that should be installed, e.g. etc/init.d/
	# (2) A file section_mkdir that containts mkdir commands
	# (3) A file section_install that contains install commands
	# (4) A file section_files that contains file lines
	# (5) A file section_run that containts run commands on target system
	
	optdir = ""
	if len(sys.argv) > 4:
		optdir = sys.argv[4]
	
	sys.exit(RpmCreator(sys.argv[1], sys.argv[2], sys.argv[3], optdir)())
