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
parser.add_argument('--eg_release', type=int, help="EG release version (eg 18)", default=18)
parser.add_argument('--e_release', type=int, help="Ensembl release version (eg 71)", default=71)
parser.add_argument('--assembly', type=int, help="Species assembly (eg 2)", default=2)
parser.add_argument('--chado_release', type=int, help="Chado dump version release number", default=35)
parser.add_argument('--dbhost', help="Core database host", default="mysql-cluster-eg-prod-3.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=4243)
parser.add_argument('--dbchadohost', help="Core database host", default="postgres-eg-pombe.ebi.ac.uk")
parser.add_argument('--dbchadoport', type=int, help="Core database port", default=5432)
parser.add_argument('--dbchadouser', help="Core database username", default="ensrw")
parser.add_argument('--dbchadopass', help="Core database password", default="xxxxx")
parser.add_argument('--file', help="Output file. Default is 'data/sql/update_gene_descriptions.sql'", default="data/sql/update_gene_descriptions.sql")
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

print args.dbchadohost, args.dbchadoport, chadodb 

try:
  conp = psycopg2.connect(host=args.dbchadohost, port=args.dbchadoport, user=pguser, password=pgpass, database=chadodb)
  cur = conp.cursor()
  cur.execute("SELECT DISTINCT g.gene_stable_id, g.desc, CASE WHEN cv.name IS NOT NULL THEN s.name ELSE 'UNKNOWN' END AS status FROM (SELECT DISTINCT CASE WHEN t1.name IN ('gene', 'psuedogene') THEN f1.feature_id WHEN t2.name IN ('gene', 'psuedogene') THEN f2.feature_id WHEN t3.name IN ('gene', 'psuedogene') THEN f3.feature_id END AS gene_feature_id, CASE WHEN t1.name IN ('gene', 'psuedogene') THEN f1.uniquename WHEN t2.name IN ('gene', 'psuedogene') THEN f2.uniquename WHEN t3.name IN ('gene', 'psuedogene') THEN f3.uniquename END AS gene_stable_id, c.name AS desc, t1.name AS biotype FROM feature f1 JOIN cvterm t1 ON (f1.type_id=t1.cvterm_id) JOIN feature_cvterm fc ON (f1.feature_id=fc.feature_id) JOIN cvterm c ON (fc.cvterm_id=c.cvterm_id) JOIN cv ON (c.cv_id=cv.cv_id) JOIN feature_relationship fr1 ON (f1.feature_id=fr1.subject_id) JOIN cvterm frt1 ON (fr1.type_id=frt1.cvterm_id) JOIN feature f2 ON (fr1.object_id=f2.feature_id) JOIN cvterm t2 ON (f2.type_id=t2.cvterm_id) LEFT JOIN feature_relationship fr2 ON (f2.feature_id=fr2.subject_id) LEFT JOIN cvterm frt2 ON (fr2.type_id=frt2.cvterm_id) LEFT JOIN feature f3 ON (fr2.object_id=f3.feature_id AND frt2.name='part_of') LEFT JOIN cvterm t3 ON (f3.type_id=t3.cvterm_id) WHERE cv.name='PomBase gene products') g JOIN feature f ON (f.feature_id=g.gene_feature_id) JOIN cvterm t ON (f.type_id=t.cvterm_id) LEFT JOIN feature_cvterm fc ON (f.feature_id=fc.feature_id) LEFT JOIN cvterm s ON (fc.cvterm_id=s.cvterm_id) LEFT JOIN cv ON (s.cv_id=cv.cv_id AND cv.name='PomBase gene characterisation status');")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    stable_id = row[0]
    description = re.sub('\'','\\\'', row[1])
    status = row[2]
    if description == None:
      description = ''
    if stable_id == None:
      print stable_id
      print "\t" + description
    else:
      if stable_id in chado:
        if status == 'UNKNOWN':
          continue
        chado[stable_id] = {'description': description, 'status': status}
      else:
        chado[stable_id] = {'description': description, 'status': status}
except Exception, e:
  print "PostgreSQL Error %s: %s" % (e.pgcode,e.pgerror)
  sys.exit(1)
finally:    
  if conp:    
    conp.close()


print args.dbhost, args.dbport, sppdb
try:
  conm = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro', db=sppdb)
  cur = conm.cursor()
  cur.execute("SELECT gene.stable_id, description, status FROM gene;")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    stable_id = row[0]
    description = row[1]
    if description == None:
      description = ''
    else:
      description = re.sub('\'','\\\'', description[1])
    eg[stable_id] = {'description': description, 'status' : row[2]}
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  if conm:    
    conm.close()

print list(set(chado.keys()) - set(eg.keys()))
print list(set(eg.keys()) - set(chado.keys()))

print 'Loading Update file ...'

f = open(args.file, 'w')
for k in chado.keys():
  chado_desc   = chado[k]['description'] + ' [Source:PomBase;Acc:' + k + ']'
  chado_status = chado[k]['status']
  if (k in eg):
    if (chado_desc != eg[k]['description']):
      f.write('UPDATE gene SET gene.description=\'' + chado[k]['description'] + ' [Source:PomBase;Acc:' + k + ']\' WHERE gene.stable_id=\'' + k + '\'; # Was \'' + eg[k]['description'] + "\'\n")
    if (chado_status != eg[k]['status']):
      f.write('UPDATE gene SET gene.status=\'' + chado[k]['status'] + '\' WHERE gene.stable_id=\'' + k + '\'; # Was \'' + eg[k]['status'] + "\'\n")
  else:
    '??? EG Missing ' + k
f.close()

