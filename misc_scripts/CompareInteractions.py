#!/usr/bin/python

import MySQLdb as mdb
import psycopg2
import psycopg2.extras
import psycopg2.extensions
from psycopg2 import OperationalError
import sys
import argparse

parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--division', help="The EG division (eg EnsemblFungi)", default="EnsemblFungi")
parser.add_argument('--species', help="The dataset species name (eg schizosaccharomyces_pombe)", default="schizosaccharomyces_pombe")
parser.add_argument('--eg_release', type=int, help="EG release version (eg 21)", default=21)
parser.add_argument('--e_release', type=int, help="Ensembl release version (eg 74)", default=74)
parser.add_argument('--assembly', type=int, help="Species assembly (eg 2)", default=2)
parser.add_argument('--chado_release', type=int, help="Chado dump version release number", default=41)
parser.add_argument('--dbhost', help="Core database host", default="mysql-cluster-eg-prod-3.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=4243)
parser.add_argument('--dbchadohost', help="Core database host", default="postgres-eg-pombe.ebi.ac.uk")
parser.add_argument('--dbchadoport', type=int, help="Core database port", default=5432)
parser.add_argument('--dbchadouser', help="Core database username", default="ensrw")
parser.add_argument('--dbchadopass', help="Core database password", default="xxxxx")
parser.add_argument('--file', help="Output file. Default is 'data/sql/update_gene_names_synonyms_test.sql'", default="data/sql/update_gene_names_synonyms_test.sql")
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

print args.dbchadohost, args.dbchadoport, chadodb 

try:
  conp = psycopg2.connect(host=args.dbchadohost, port=args.dbchadoport, user=args.dbchadouser, password=args.dbchadopass, database=chadodb)
  cur = conp.cursor()
  cur.execute("SELECT t.A, COUNT(DISTINCT t.B), SUM(ig), SUM(ip) FROM (SELECT f1.uniquename AS A, f2.uniquename AS B, CASE WHEN frt.name='interacts_genetically' THEN 1 END AS ig, CASE WHEN frt.name='interacts_physically' THEN 1 END AS ip FROM feature f1 JOIN feature_relationship fr ON (f1.feature_id=fr.subject_id) JOIN feature f2 ON (f2.feature_id=fr.object_id) JOIN cvterm frt ON (fr.type_id=frt.cvterm_id) JOIN cv ON (frt.cv_id=cv.cv_id) LEFT JOIN feature_relationshipprop frp ON (fr.feature_relationship_id=frp.feature_relationship_id) LEFT JOIN cvterm frpt ON (frp.type_id=frpt.cvterm_id) WHERE cv.name = 'PomBase interaction types' UNION SELECT f2.uniquename AS A, f1.uniquename AS B, CASE WHEN frt.name='interacts_genetically' THEN 1 END AS ig, CASE WHEN frt.name='interacts_physically' THEN 1 END AS ip FROM feature f1 JOIN feature_relationship fr ON (f1.feature_id=fr.subject_id) JOIN feature f2 ON (f2.feature_id=fr.object_id) JOIN cvterm frt ON (fr.type_id=frt.cvterm_id) JOIN cv ON (frt.cv_id=cv.cv_id) LEFT JOIN feature_relationshipprop frp ON (fr.feature_relationship_id=frp.feature_relationship_id) LEFT JOIN cvterm frpt ON (frp.type_id=frpt.cvterm_id) WHERE cv.name = 'PomBase interaction types') AS t GROUP BY t.A;")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    stable_id = row[0]
    all_genes = row[1]
    if all_genes == None:
      all_genes = 0
    
    ig = row[2]
    if ig == None:
      ig=0
    
    ip = row[3]
    if ip == None:
      ip=0
      
    chado[stable_id] = {'all': int(all_genes), 'ig': int(ig), 'ip': int(ip)}
except Exception, e:
  #print "PostgreSQL Error %s: %s" % (e.pgcode,e.pgerror)
  print e
  sys.exit(1)
finally:    
  if conp:    
    conp.close()


print args.dbhost, args.dbport, sppdb

try:
  conm = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro', db=sppdb)
  cur = conm.cursor()
  cur.execute("SELECT t.stable_id, COUNT(DISTINCT t.dbprimary_acc), SUM(t.ig), SUM(t.ip) FROM (SELECT DISTINCT gene.stable_id, ax.dbprimary_acc, IF(x.dbprimary_acc='PBO:0000037',1,0) AS ig, IF(x.dbprimary_acc='PBO:0000038',1,0) AS ip FROM gene JOIN transcript ON (gene.gene_id=transcript.gene_id) JOIN object_xref ON (transcript.transcript_id=object_xref.ensembl_id AND object_xref.ensembl_object_type='Transcript') JOIN xref x ON (object_xref.xref_id=x.xref_id) JOIN external_db ON (x.external_db_id=external_db.external_db_id) JOIN associated_xref ON (object_xref.object_xref_id=associated_xref.object_xref_id) JOIN xref ax ON (associated_xref.xref_id=ax.xref_id) WHERE external_db.db_name='PBO' AND x.dbprimary_acc IN ('PBO:0000037', 'PBO:0000038') AND associated_xref.condition_type IN ('InteractorA', 'InteractorB')) AS t GROUP BY t.stable_id;")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    stable_id = row[0]
    all_genes = int(row[1])
    if all_genes == None:
      all_genes = 0
    
    ig = int(row[2])
    if ig == None:
      ig=0
    
    ip = int(row[3])
    if ip == None:
      ip=0
      
    eg[stable_id] = {'all': int(all_genes), 'ig': int(ig), 'ip': int(ip)}
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  if conm:    
    conm.close()

k = list(set(eg.keys()).intersection(set(chado.keys())))
print len(k), len(eg), len(chado)

for g in k:
  if eg[g]['all'] != chado[g]['all'] or eg[g]['ig'] != chado[g]['ig'] or eg[g]['ip'] != chado[g]['ip']:
    print g, eg[g], chado[g]
  
