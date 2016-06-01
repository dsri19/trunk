import sys

def clean_dependencies(dependencies):
	for target in dependencies.keys():
		tmp = []
		
		for dependency in dependencies[target]:
			if dependency in dependencies.keys():
				tmp.append(dependency)
			
		#print "Cleaned Deps for %s : %s" % (target, tmp)
		dependencies[target] = tmp
	
	return dependencies
	
def get_dependencies_without_dependencies(dependencies):
	ret = []
	for target in dependencies.keys():
		if len(dependencies[target]) == 0:
			ret.append(target)

	return ret
	
def print_dependencies(dependencies):
	for target in dependencies.keys():
		print "Target %s depends on: %s" % (target, str(dependencies[target]))
	
targets = sys.argv[1].split(';')
dependencies_per_target = ("%s;" % (sys.argv[2])).split('---;')

dependencies = {}

idx = 0
while idx < len(targets):
	dependencies[targets[idx]] = dependencies_per_target[idx].split(';')
	idx = idx + 1

# Clean dependencies - we want to have local dependencies in our lists only
while len(dependencies) > 0:
	dependencies = clean_dependencies(dependencies)
	l = get_dependencies_without_dependencies(dependencies)
	if len(l) == 0:
		print "ENDLESS LOOP"
		sys.exit(1)
		
	for i in l:
		print i,
		dependencies.pop(i, None)