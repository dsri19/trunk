import sys
import os
import zipfile
import time


def unzip(archive_path, target_path):
	zf = zipfile.ZipFile(archive_path, 'r')
	for zi in zf.infolist():
		zf.extract(zi, target_path)
		date_time = time.mktime(zi.date_time + (0, 0, -1))
		os.utime(os.path.join(target_path,zi.filename), (date_time, date_time))
	zf.close()

if __name__ == '__main__':
    unzip(sys.argv[1], sys.argv[2])
