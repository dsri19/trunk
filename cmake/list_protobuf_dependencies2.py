#!/usr/bin/python

import sys

def main():
	if (len(sys.argv) < 2):
		sys.stderr.write("Usage: %s <PROTOFILE>" % sys.argv[0])
		sys.exit(1)

	filename = ""
	if (len(sys.argv) == 2):
		filename = sys.argv[1]
	else:
		sys.path.append(sys.argv[1])
		filename = sys.argv[2]
	
	import google.protobuf.descriptor_pb2

	f = open(filename, 'rb')
	content = f.read()

	descriptor = google.protobuf.descriptor_pb2.FileDescriptorSet.FromString(content)

	list_of_fields = descriptor.ListFields()
	for item in list_of_fields:
		files = item[1]
		for file in files:
			if isinstance(file, google.protobuf.descriptor_pb2.FileDescriptorProto):
				# HOTFIX: IS this the DAF protobuf file? If yes, bail
				if (file.name.find("DAF") == -1) and (file.name.find("TID") == -1):
					print file.name,

if __name__ == "__main__":
	main()
