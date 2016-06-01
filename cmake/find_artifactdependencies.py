#!/usr/bin/python

import os
import re
import sys
import argparse

from sets import Set

target_directory = os.environ.get('ARTIFACTORY_DIR')
if target_directory == None:
	target_directory = os.environ.get('TMP') + '/artifactory'

dependencies = {}
edges = Set()

def search_in_local_cache(cacheDir, artifactName, version):
	specList = ["-win64-vc110-", "-win64-", "-"]
	cacheDir = os.path.join(target_directory, artifactName)
	for spec in specList:
		completeCacheDir = cacheDir + spec + version
		# print "......: "+completeCacheDir
		if (os.path.exists(completeCacheDir)):
			# print "found " + completeCacheDir
			return completeCacheDir
	return None

def parse_dependency_versions(file_name):
	return dict(line.strip().split('=') for line in open( file_name )
							if not line.strip().startswith('#') and not line.strip() == "")

def buildDependencies( reference, version, target_directory ):
	global dependencies
	
	dependencies[reference] = []
	artefactDir = search_in_local_cache( target_directory, reference, version )
	if artefactDir:
		depsFileName = os.path.join(artefactDir,'dependency_versions.config')
		if (os.path.exists(depsFileName)):
			dep_versions = parse_dependency_versions(depsFileName)
			for k, v in dep_versions.items():
				dependencies[reference].append(k)
	else:
		print >> sys.stderr, reference + " not found"
        


def buildEdges(artifactName):
	global dependencies
	global edges
	
	# directDependencies = dependencies[artifactName]
	# print directDependencies
        for k, directDeps in dependencies.items():
		if artifactName in directDeps:
			# print directDeps
			edge = (k, artifactName)
			edges.add(edge)
			buildEdges(k)


def no_deps(items, deps, built):
    """ Get items that have no unbuilt dependencies """
    return [i for i in items if not depends_on_unbuilt(i, deps, built)]


def depends_on_unbuilt(item, deps, built):
    """ See if item depends on any item not built """
    if not item in deps:
        return False
    
    return any(d not in built for d in deps[item])


def resolve_paralell(items, deps):
    """ Returns a list of sets of tasks that can be done paralelly """
    items = set(items)
    built = set()
    out = []
    while True:
        if not items:
            break

        no_d = set(no_deps(items, deps, built))
        items -= no_d
        
        built |= no_d
        out.append(no_d)
        
        if set(sum(deps.values(), [])) == built:
            out.append(items)
            break
        
    return out

def print_to_tgf(nodes, edges):
	for node in nodes:
		print node + " " + node
	print("#")
	for edge in edges:
		print edge[0] + " " + edge[1]

def print_resolved_order(nodes, edges):
	deps = {}
	
	for edge in edges:
		if edge[0] not in deps:
			deps[edge[0]] = []
		deps[edge[0]].append(edge[1])

	resolved = resolve_paralell(nodes, deps)
	# print resolved

	for s in resolved:
		for value in s:
			print value,
		print ""


parser = argparse.ArgumentParser(description='Process some artifac dependencies.')
parser.add_argument('artifact', type=str, help='name of the artifact')
parser.add_argument('-f', '--format', type=str, choices=['tgf', 'plain'],  default='tgf', help='default=tgf')

args = parser.parse_args()
		
name = args.artifact

# print >> sys.stderr, "Searching for %s" % (name)
dep_versions = parse_dependency_versions('dependency_versions.config')
# print dep_versions
for k, v in dep_versions.items():
	# print "searching for " + k
	buildDependencies( k, v, target_directory )

buildEdges(name)

nodes = Set()
for edge in edges:
	nodes.add(edge[0])
	nodes.add(edge[1])

if args.format == 'plain':
	print_resolved_order(nodes, edges)
else:
	print_to_tgf(nodes, edges)



