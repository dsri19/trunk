import filelock
import json
import os
import re
import sys
import urllib2

password_mgr = urllib2.HTTPPasswordMgrWithDefaultRealm()
handler = urllib2.HTTPBasicAuthHandler(password_mgr)
opener = urllib2.build_opener(handler)
urllib2.install_opener(opener)

def authenticate_url(url):
	password_mgr.add_password(None, url, "dev", "devdev")

class Artifactory:

	def __init__(self, server):
		self.__server__ = server

	def parse_version(self, artifact, name):
		basename = os.path.basename(artifact["path"])
		(artifact_name, suffix) = os.path.splitext(basename)
		if not artifact_name.startswith("%s" % name):
			return None
			
		if artifact_name == name:
			return "MATCH" # dunno what to do here
			
		m = re.match(name + '-(\d+)', artifact_name)
		if m:
			return m.group(1)
		
		return None
		
	def search(self, name):
		url = "%s/api/search/artifact?name=%s" % (self.__server__, urllib2.quote(name))
		print >> sys.stderr, "URL: %s" % (url)

		results = []
		try:
			authenticate_url(url)
			request = urllib2.urlopen(url)
			results = json.loads(request.read())["results"]
		except urllib2.URLError:
			pass
		
		content = []
		for item in results:
			authenticate_url(item["uri"])
			content.append(json.loads(urllib2.urlopen(item["uri"]).read()))
			
		return content

	def search_latest_version(self, name):
		latest = None
		latest_version = None
	
		for artifact in self.search(name):
			version = self.parse_version(artifact, name)
			
			if version > latest_version:
				latest_version = version
				latest = artifact
			
		return latest

def download(uri, filename):
	lock = None
	try:
		lock = filelock.FileLock(filename, timeout=30, delay=0.5)
		lock.acquire()
		
		authenticate_url(uri)
		input = urllib2.urlopen(uri)
		
		#read in smaller chunks to avoid urllibs problems with large files
		#see: http://stackoverflow.com/questions/1517616/stream-large-binary-files-with-urllib2-to-file
		CHUNK = 16 * 1024
		with open(filename, 'wb') as output:
			while True:
				chunk = input.read(CHUNK)
				if not chunk: 
					break
				output.write(chunk)
	except filelock.FileLockException:
		print "Failed to acquire file lock - timeout"
		pass
	finally:
		if lock:
			lock.release()

def check_sha(filename, sha):
	if not os.path.exists(filename) or not os.path.isfile(filename):
		return False

	with open(filename, "rb") as sha_file:
		tmp_sha = sha_file.read()
		if tmp_sha == sha:
			return True;

	return False

def save_sha(filename, sha):
	with open(filename, "wb") as sha_file:
		sha_file.write(sha)

def search_in_local_cache(cacheDir, artifactName):
	pass
