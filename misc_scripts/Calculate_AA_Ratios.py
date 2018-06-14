#!/usr/bin/env python

#get library modules
import sys, os, argparse

aa_list = ['A', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'Y']
aa_used = {}
pp = ""
fi = open("data/tmp/pep.fa", "r")
print "Stable_ID\tA\tC\tD\tE\tF\tG\tH\tI\tK\tL\tM\tN\tP\tQ\tR\tS\tT\tV\tW\tY"
for line in fi:
  line = line.rstrip()
  if len(line) == 0:
    continue
  if line[0] == '>':
    if pp != "" and gene != "":
      for aa_id in xrange(len(pp)):
        if pp[aa_id] in aa_used.keys():
          aa_used[pp[aa_id]] += 1
        else:
          aa_used[pp[aa_id]] = 1
      outline = gene
      for aa in aa_list:
        outline += "\t"
        if aa in aa_used.keys():
          outline += str(aa_used[aa])
        else:
          outline += str(0)
      print outline
    gline = line[1:].split("|")
    gene = gline[0]
    pp = ""
    aa_used = {}
    continue
  pp += line.replace(" ", "")
fi.close()
