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
#fo = open('Spombe.2013-01-02.filt3c.nr57-final.snps.anno-snpeff3.cleaned3.AB325691.vcf', 'w')
fo = open(args.outfile, 'w')
for line in fi:
  if len(line) == 0:
    continue
  if line[0] == '#':
    fo.write(line)
    continue
  line = line.rstrip()
  
  v = line.split('\t');
  params = v[8].split(':')
  out = v[0:8]
  
  try:
    paramIndex = params.index(args.param)
    del params[paramIndex]
    out.append(':'.join(params))
    for d in v[9:]:
      dv = d.split(':')
      del dv[paramIndex]
      out.append(':'.join(dv))
  except ValueError:
    out.append(':'.join(params))
    out += v[9:]
  fo.write("\t".join(out) + "\n")

fi.close()
fo.close()
