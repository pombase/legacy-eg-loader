#!/usr/bin/env python
#get library modules
import sys, os

datasets = []
for file in os.listdir('.'):
  if file.endswith(".bedGraph"):
    datasets.append(file.replace('.bedGraph', ''))
 
for ds in datasets:
  fi = open(ds + '.bedGraph', 'r')
  f1 = open(ds + '.wig', 'w')
  chrom = ''
  variableStep = 0
  for line in fi:
    sline = line.split('\t')
    if (len(sline) != 4):
      continue
    if (sline[0] != chrom or int(sline[2])-int(sline[1]) != variableStep):
      chrom = sline[0]
      variableStep = int(sline[2])-int(sline[1])
      f1.write("variableStep chrom=" + chrom + " span=" + str(variableStep) + "\n")
    f1.write(str(int(sline[1]) + 1) + "\t" + sline[3])
  fi.close()
  f1.close()
