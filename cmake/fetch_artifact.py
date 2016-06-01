#!/usr/bin/python

import os
import shutil
import sys

import unzip

print >> sys.stderr, "Running on %s" % (sys.version)

from artifactory_tools import *

# Configuration
#
# Read from ArtifactoryClient.cfg
from ConfigParser import SafeConfigParser

# workaround for self signed certificates in 2.7.9
import ssl
if hasattr(ssl, '_create_unverified_context'):
    ssl._create_default_https_context = ssl._create_unverified_context

parser = SafeConfigParser()
cfg_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ArtifactoryClient.cfg')
print >> sys.stderr, "Reading Configuration from %s" % (cfg_file)
parser.read(cfg_file)

names = sys.argv[5:]
access_server = sys.argv[1]
target_directory = sys.argv[2]
tmp_directory = sys.argv[3]
repository_url = sys.argv[4]

repository = Artifactory(repository_url)

for name in names:
	print >> sys.stderr, "Searching for %s" % (name)
	try:
		# disable artifactory access
		if access_server == "true":
			artifact = repository.search_latest_version(name)
		else:
			artifact = None

		if (not artifact):
			cacheDir = os.path.join(target_directory, name)
			if (os.path.exists(cacheDir)):
				print cacheDir
				break			
		else:
			artifact_basename = os.path.basename(artifact["path"])
			artifact_name = os.path.splitext(artifact_basename)[0]

			archive_sha_file = os.path.join(tmp_directory, ".sha_%s" % (artifact_name))
			archive_file = os.path.join(tmp_directory, artifact_basename)

			if os.path.exists(archive_file) & os.path.isfile(archive_file) & check_sha(archive_sha_file, artifact["checksums"]["sha1"]):
				print >> sys.stderr, "Artifact already successfully downloaded at %s" % (archive_file)
			else:
				print >> sys.stderr, "Downloading artifact from %s ..." % (artifact["downloadUri"]),
				download(artifact["downloadUri"], archive_file)
				print >> sys.stderr, "done"
				save_sha(archive_sha_file, artifact["checksums"]["sha1"])
			
			if artifact_name.find("-SNAPSHOT") == -1:
				target_directory = os.path.join(target_directory, artifact_name)
			else:
				target_directory = os.path.join(target_directory, ("%s.%s" % (artifact_name, artifact["checksums"]["sha1"])))			
			lock = None
			ziplock = None
			try:
				lock = filelock.FileLock(target_directory, timeout=30, delay=0.5)
				lock.acquire()
				
				output_sha_file = os.path.join(target_directory, ".sha_output_%s" % (artifact_name))
				if os.path.exists(target_directory) & os.path.isdir(target_directory) & check_sha(output_sha_file, artifact["checksums"]["sha1"]):
					print >> sys.stderr, "Artifact already successfully unpacked at %s" % (target_directory)
					print target_directory
				else:
					print >> sys.stderr, "Unpacking artifact archive at %s ..." % (target_directory),
					if os.path.exists(target_directory):
						shutil.rmtree(target_directory)
					if os.name == 'nt':
						import zipfile
						ziplock = filelock.FileLock(archive_file, timeout=30, delay=0.5)
						ziplock.acquire()
						unzip.unzip(archive_file, target_directory)
					else:
						from subprocess import call
						call(["unzip", "-q", "-o", archive_file, "-d", target_directory])

					print >> sys.stderr, "done"
					save_sha(output_sha_file, artifact["checksums"]["sha1"])
					
					print target_directory
					
				break
			except filelock.FileLockException:
				print "Failed to acquire file lock - timeout"
				pass
			finally:
				if lock:
					lock.release()
				if ziplock:
					ziplock.release()
	except urllib2.HTTPError as e:
		if e.code != 404:
			raise e
