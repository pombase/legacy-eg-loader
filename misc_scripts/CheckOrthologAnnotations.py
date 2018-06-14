#!/usr/bin/python

import MySQLdb as mdb
import psycopg2
import psycopg2.extras
import psycopg2.extensions
from psycopg2 import OperationalError
import sys
import re
import argparse

parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--division', help="The EG division (eg EnsemblFungi)", default="EnsemblFungi")
parser.add_argument('--species', help="The dataset species name (eg schizosaccharomyces_pombe)", default="schizosaccharomyces_pombe")
parser.add_argument('--eg_release', type=int, help="EG release version (eg 23", default=23)
parser.add_argument('--e_release', type=int, help="Ensembl release version (eg 76)", default=76)
parser.add_argument('--assembly', type=int, help="Species assembly (eg 2)", default=2)
parser.add_argument('--chado_release', type=int, help="Chado dump version release number", default=47)
parser.add_argument('--dbhost', help="Core database host", default="mysql-cluster-eg-prod-3.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=4243)
parser.add_argument('--dbuser', help="Core database username", default='')
parser.add_argument('--dbpass', help="Core database password", default='')
parser.add_argument('--dbchadohost', help="Core database host", default="postgres-eg-pombe.ebi.ac.uk")
parser.add_argument('--dbchadoport', type=int, help="Core database port", default=5432)
parser.add_argument('--dbchadouser', help="Core database username", default="ensrw")
parser.add_argument('--dbchadopass', help="Core database password", default="xxxxx")
args = parser.parse_args()

division      = args.division   # 'EnsemblFungi'
species       = args.species    # 'schizosaccharomyces_pombe'
eg_release    = args.eg_release # 18
e_release     = args.e_release  # 71
chado_release = args.chado_release  # 35
assembly      = args.assembly   # 2

sppdb = species + "_core_" + str(eg_release) + "_" + str(e_release) + "_" + str(assembly)
chadodb = 'pombase_chado_v' + str(args.chado_release)

pguser = args.dbchadouser
pgpass = args.dbchadopass

conp = None
conm = None

chado = dict()
eg    = dict()

#fi = open('/homes/mcdowall/Documents/Code/python/PomBase_v33_GeneName_Synonym.tsv', 'r')
#for line in fi:
#  line = line.replace('\n', '')
#  sline = line.split('\t')
#  chado[sline[1]] = {'name': sline[0], 'synonyms':sline[2].split(',')}
#fi.close()

try:
  conp = psycopg2.connect(host=args.dbchadohost, port=args.dbchadoport, user=pguser, password=pgpass, database=chadodb)
  cur = conp.cursor()
  cur.execute("SELECT tf.uniquename, ef.uniquename, ef.name FROM feature tf JOIN feature_relationship fr ON (tf.feature_id=fr.object_id) JOIN cvterm frt ON (fr.type_id=frt.cvterm_id) JOIN feature ef ON (fr.subject_id=ef.feature_id) WHERE frt.name='orthologous_to';")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    if row[0] in chado:
     chado[row[0]][row[1]] = row[2]
    else:
     chado[row[0]] = {row[1] : row[2]}
except Exception, e:
  print "PostgreSQL Error %s: %s" % (e.pgcode,e.pgerror)
  sys.exit(1)
finally:    
  if conp:    
    conp.close()


try:
  conm = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro', db=sppdb)
  cur = conm.cursor()
  cur.execute("select gene.stable_id, xref.dbprimary_acc, xref.display_label from gene join object_xref on (gene.gene_id=object_xref.ensembl_id) join xref on (object_xref.xref_id=xref.xref_id) JOIN external_db ON (xref.external_db_id=external_db.external_db_id) where external_db.db_name = 'PomBase_Ortholog' and object_xref.ensembl_object_type='Gene';")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    if row[0] in eg:
      eg[row[0]][row[1]] = row[2]
    else:
      eg[row[0]] = {row[1] : row[2]}
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  if conm:    
    conm.close()

if len(list(set(chado.keys()) - set(eg.keys()))) != 0 or len(list(set(eg.keys()) - set(chado.keys()))) != 0:
  print "ERROR ..."
  print "================================================================================"
  print "Stable IDs in Chado but absent in EG"
  print "================================================================================"
  print list(set(chado.keys()) - set(eg.keys()))
  for k in list(set(chado.keys()) - set(eg.keys())):
    print k
    print chado[k]
  print ""
  print "================================================================================"
  print "Stable IDs in EG but absent in Chado"
  print "================================================================================"
  print list(set(eg.keys()) - set(chado.keys()))
  for k in list(set(eg.keys()) - set(chado.keys())):
    print k
    print eg[k]
  print ""
  print "================================================================================"
  #sys.exit(1)

# print 'Comparing Orthologs between Chado and Core ...'

for k in chado.keys():
  if k in eg:
    if len(list(set(chado[k].keys()) - set(eg[k].keys()))) > 0:
      print "WARNING - Exiting Early"
      print k
      print list(set(chado[k].keys()) - set(eg[k].keys()))
      print chado[k]
      print eg[k]
      #sys.exit(1)

