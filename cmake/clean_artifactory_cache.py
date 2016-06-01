#!/usr/bin/python

import shutil
import os
import sys

tmpdir = None
if "ARTIFACTORY_DIR" in os.environ:
    artifactory_cache = os.environ["ARTIFACTORY_DIR"]
else:
    if sys.platform == "win32":
    	tmpdir = os.environ["TEMP"]
    else:
        tmpdir = os.environ["TMPDIR"]

    artifactory_cache = os.path.join(tmpdir, "artifactory")

shutil.rmtree(artifactory_cache)
