#!/usr/bin/env python

#get library modules
import MySQLdb as mdb
import sys, os, argparse
import math
from decimal import *

parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--host', help="Database host (eg mysql-devel-3)", default="mysql-eg-devel-3.ebi.ac.uk")
parser.add_argument('--port', help="Database port (eg 1234)", default="4208")
parser.add_argument('--user', help="Database username (eg ensro)", default="ensro")
parser.add_argument('--pswd', help="Database password (eg S3crEt)", default="xxx")
parser.add_argument('--db',   help="Core db (eg schizosaccharomyces_pombe_core_27_80_2)", default="schizosaccharomyces_pombe_core_27_80_2")
parser.add_argument('--loaddb', help="Load db (eg 1)", default="0")
parser.add_argument('--translation_id', help="Stable_id for the translation", default="")
args = parser.parse_args()

host = args.host # 'mysql-devel-3.ebi.ac.uk'
port = args.port # '4208'
user = args.user # 'ensro'
pwd  = args.pswd # 'xxx'
db   = args.db # 'schizosaccharomyces_pombe_core_27_80_2'
load_db = int(args.loaddb) # 0
translation = args.translation_id # 'SPAC123.00c'

codons_used = {}
aa_used     = {}
ter_codon   = ['TAA', 'TAG', 'TGA']
codon_trans = {'ATT': 'I', 'ATC': 'I', 'ATA': 'I', 'CTT': 'L', 'CTC': 'L', 'CTA': 'L', 'CTG': 'L', 'TTA': 'L', 'TTG': 'L', 'GTT': 'V', 'GTC': 'V', 'GTA': 'V', 'GTG': 'V', 'TTT': 'F', 'TTC': 'F', 'ATG': 'M', 'TGT': 'C', 'TGC': 'C', 'GCT': 'A', 'GCC': 'A', 'GCA': 'A', 'GCG': 'A', 'GGT': 'G', 'GGC': 'G', 'GGA': 'G', 'GGG': 'G', 'CCT': 'P', 'CCC': 'P', 'CCA': 'P', 'CCG': 'P', 'ACT': 'T', 'ACC': 'T', 'ACA': 'T', 'ACG': 'T', 'TCT': 'S', 'TCC': 'S', 'TCA': 'S', 'TCG': 'S', 'AGT': 'S', 'AGC': 'S', 'TAT': 'Y', 'TAC': 'Y', 'TGG': 'W', 'CAA': 'Q', 'CAG': 'Q', 'AAT': 'N', 'AAC': 'N', 'CAT': 'H', 'CAC': 'H', 'GAA': 'E', 'GAG': 'E', 'GAT': 'D', 'GAC': 'D', 'AAA': 'K', 'AAG': 'K', 'CGT': 'R', 'CGC': 'R', 'CGA': 'R', 'CGG': 'R', 'AGA': 'R', 'AGG': 'R'}
aa_codon    = {'I': ['ATT', 'ATC', 'ATA'], 'L': ['CTT', 'CTC', 'CTA', 'CTG', 'TTA', 'TTG'], 'V': ['GTT', 'GTC', 'GTA', 'GTG'], 'F': ['TTT', 'TTC'], 'M': ['ATG'], 'C': ['TGT', 'TGC'], 'A': ['GCT', 'GCC', 'GCA', 'GCG'], 'G': ['GGT', 'GGC', 'GGA', 'GGG'], 'P': ['CCT', 'CCC', 'CCA', 'CCG'], 'T': ['ACT', 'ACC', 'ACA', 'ACG'], 'S': ['TCT', 'TCC', 'TCA', 'TCG', 'AGT', 'AGC'], 'Y': ['TAT', 'TAC'], 'W': ['TGG'], 'Q': ['CAA', 'CAG'], 'N': ['AAT', 'AAC'], 'H': ['CAT', 'CAC'], 'E': ['GAA', 'GAG'], 'D': ['GAT', 'GAC'], 'K': ['AAA', 'AAG'], 'R': ['CGT', 'CGC', 'CGA', 'CGG', 'AGA', 'AGG']}

###
# Calculate the ratios table.
###
codon_count = 0
fi = open("data/tmp/cdna_nointrons_noutrs_ge100k.fa", "r")
for line in fi:
  if line[0] == '>':
    continue
  line = line.rstrip()
  n = 3
  for codon in [line[i:i+n] for i in range(0,len(line), n)]:
    if codon in ter_codon:
      continue
    if codon in codons_used.keys():
      codons_used[codon] += 1
    else:
      codons_used[codon] = 1
    codon_count+=1
    
    if codon_trans[codon] in aa_used.keys():
      aa_used[codon_trans[codon]] += 1
    else:
      aa_used[codon_trans[codon]] = 1
fi.close()

aa_rand_usage = {}
rscu     = {}
rscu_max = {}
for aa in aa_used.keys():
  aa_rand_usage[aa] = (1.0/len(aa_codon[aa]))*aa_used[aa]
  for codon in aa_codon[aa]:
    rscu[codon] = codons_used[codon]/((1.0/len(aa_codon[aa]))*aa_used[aa])
    if aa in rscu_max.keys():
      if rscu[codon] > rscu_max[aa]:
        rscu_max[aa] = rscu[codon]
    else:
      rscu_max[aa] = rscu[codon]

###
# Calcualte the CAI values for each protein
###
conm = 0
cur  = 0
try:
  add_attrib = "INSERT INTO translation_attrib select translation.translation_id, (select attrib_type_id from attrib_type where attrib_type.code='CodonAdaptIndex') as attrib_type_id, %(cai)s as value from gene join transcript on (gene.gene_id=transcript.gene_id) join translation on (transcript.transcript_id=translation.transcript_id) where gene.stable_id=%(stable_id)s;"
  if (load_db == 1):
    conm = mdb.connect(host=host, port=int(port), user=user, passwd=pwd, db=db)
    cur = conm.cursor()
  
  fi = open("data/tmp/cdna_nointrons_noutrs.fa", "r")
  gene = ""
  pp   = ""
  cai_obs = Decimal(0)
  cai_max = Decimal(0)
  codon_c = 0
  for line in fi:
    line = line.rstrip()
    if len(line) == 0:
      continue
    if line[0] == '>':
      if pp != "" and gene != "":
        n = 3
        for codon in [pp[i:i+n] for i in range(0,len(pp), n)]:
          if codon in ter_codon:
            continue
          if len(codon) != 3:
            print "#ERROR: CODON; GENE: " + gene
            continue
          if cai_obs == 0:
            cai_obs = Decimal(rscu[codon])
          else:
            cai_obs *= Decimal(rscu[codon])
          if cai_max == 0:
            cai_max = Decimal(rscu_max[codon_trans[codon]])
          else:
            cai_max *= Decimal(rscu_max[codon_trans[codon]])
          codon_c += 1
          #print cai_max
        cai_obs **= Decimal(1.0/codon_c)
        cai_max **= Decimal(1.0/codon_c)
        #print str(cai_obs) + " : " + str(cai_max) + " : " + str(codon_c)
        if (math.isinf(cai_max)):
          break
        if load_db == 1:
          insert_data = {
            'stable_id': gene,
            'cai':       str(cai_obs/cai_max)
          }
          cur.execute(add_attrib, insert_data)
          conm.commit()
        else:
          if translation == "" or translation == gene:
            print gene + "\t" + str(cai_obs/cai_max)
      gene = line[1:]
      pp = ""
      cai_obs = 0.0
      cai_max = 0.0
      codon_c = 0
      continue
    pp += line.replace(" ", "")
  fi.close()

  if pp != "":
    n = 3
    for codon in [pp[i:i+n] for i in range(0,len(pp), n)]:
      if codon in ter_codon:
        continue
      if len(codon) != 3:
        print "#ERROR: CODON; GENE: " + gene
        continue
      if cai_obs == 0:
        cai_obs = Decimal(rscu[codon])
      else:
        cai_obs *= Decimal(rscu[codon])
      if cai_max == 0:
        cai_max = Decimal(rscu_max[codon_trans[codon]])
      else:
        cai_max *= Decimal(rscu_max[codon_trans[codon]])
      codon_c += 1
    cai_obs **= Decimal(1.0/codon_c)
    cai_max **= Decimal(1.0/codon_c)
    if load_db == 1:
      insert_data = {
        'stable_id': gene,
        'cai':       str(cai_obs/cai_max)
      }
      cur.execute(add_attrib, insert_data)
      conm.commit()
    else:
      print gene + "\t" + str(cai_obs/cai_max)

  
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  if conm:    
    conm.close()
