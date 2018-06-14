#!/usr/bin/env python

#get library modules
import sys, os, json

files = ['GeneModels_chr1', 'GeneModels_chr2', 'GeneModels_chr3', 'GeneModels_chr4', 'GeneModels_chr5', 'GeneModels_chr6']

for f in files:
  print "Reading " + f + ".json"
  
  fi = open('../data/FTP/' + f + '.json', 'r')
  jf = fi.readline()
  fi.close()  
  json_obj = json.loads(jf)
  
  print "\tGene Count: " + str(len(json_obj))
  
  step = 5
  start = 0
  end = step
  more_steps = True
  while more_steps:
    print "\twriting file " + f + "_" + str(start) + ".json"
    fo = open( '../data/caches/' + f + '_' + str(start) + '.json', 'w')
    fo.write(json.dumps(json_obj[start:end]))
    fo.close()
    
    if end>=len(json_obj):
      more_steps = False
    else:
      start+=step
      end+=step
    
