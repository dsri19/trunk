import sys
import urllib2;

from artifactory_tools import *

artifactory_file_url = sys.argv[1]
target_path = sys.argv[2]

try:
    download(artifactory_file_url, target_path)
except urllib2.HTTPError as e:
    if e.code == 404:
        sys.stderr.write("No artifact found at " + artifactory_file_url)
        sys.exit(1)
    else:
        raise e
