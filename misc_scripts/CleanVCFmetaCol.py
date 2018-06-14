#!/usr/bin/python

import os
import sys
import pprint
import argparse

parser = argparse.ArgumentParser(description='Clean up the data for a given parameter')
parser.add_argument('--infile', help="Path to the VCF file", default='test.vcf')
parser.add_argument('--outfile', help="Path to the new VCF file", default='test.out.vcf')
parser.add_argument('--param', help="Parameter to clean", default='PL')
args = parser.parse_args()

fi = open(args.infile, 'r')
fo = open(args.outfile, 'w')
for line in fi:
  if len(line) == 0:
    continue
  if line[0] == '#':
    fo.write(line)
    continue
  line = line.rstrip()
  
  v = line.split('\t');
  params = v[7].split(';')
  outparams = []
  for d in params:
    dv = d.split('=')
    if dv[0] != args.param:
      outparams.append(d)
  out = v[0:7]
  out.append(';'.join(outparams))
  out += v[8:]
  
  fo.write("\t".join(out) + "\n")
  #print "\t".join(out)

fi.close()
fo.close()
