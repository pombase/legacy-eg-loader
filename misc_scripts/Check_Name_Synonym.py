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
  cur.execute("SELECT feature.name, feature.uniquename, ARRAY_TO_STRING(ARRAY_AGG(synonym.name),',') FROM feature JOIN organism on (feature.organism_id=organism.organism_id) JOIN cvterm ON (feature.type_id=cvterm.cvterm_id) JOIN cv on (cvterm.cv_id=cv.cv_id) LEFT JOIN feature_synonym ON feature.feature_id=feature_synonym.feature_id LEFT JOIN synonym ON feature_synonym.synonym_id=synonym.synonym_id WHERE cvterm.name in ('gene', 'pseudogene') AND cv.name='sequence' AND organism.genus || '_' || organism.species = '" + species.capitalize() + "' GROUP BY feature.name, feature.uniquename;")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    stable_id = row[1]
    name = row[0]
    if name == None:
      name = stable_id
    synonym = row[2]
    if synonym == None:
      synonym = ''
    else:
      synonym = row[2].split(',')
      
    chado[stable_id] = {'name': name, 'synonyms':synonym}
except Exception, e:
  print "PostgreSQL Error %s: %s" % (e.pgcode,e.pgerror)
  print e
  sys.exit(1)
finally:    
  if conp:    
    conp.close()


#fi = open('/homes/mcdowall/Documents/Code/python/Spombe_EG17_GeneName_Synonym_v33.tsv', 'r')
#for line in fi:
#  line = line.replace('\n', '')
#  sline = line.split('\t')
#  eg[sline[1]] = {'name': sline[0], 'synonyms':sline[2].split(',')}
#fi.close()

print args.dbhost, args.dbport, sppdb

try:
  conm = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro', db=sppdb)
  cur = conm.cursor()
  #cur.execute('UPDATE xref JOIN gene ON (gene.stable_id=xref.dbprimary_acc) SET gene.display_xref_id=xref.xref_id WHERE external_db_id=50642;')
  cur.execute("SELECT xref.display_label, gene.stable_id, GROUP_CONCAT(external_synonym.synonym SEPARATOR ','), gene.display_xref_id FROM gene LEFT JOIN xref ON (gene.display_xref_id=xref.xref_id) LEFT JOIN external_synonym ON (xref.xref_id=external_synonym.xref_id) GROUP BY xref.display_label, gene.stable_id;")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    stable_id = row[1]
    name = row[0]
    if row[3] != None and name == '':
      name = stable_id
    elif row[3] == None:
      name = ''
    synonym = row[2]
    if synonym == None:
      synonym = ''
    else:
      synonym = row[2].split(',')
      
    eg[stable_id] = {'name': name, 'synonyms':synonym}
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  if conm:    
    conm.close()

#print list(set(chado.keys()) - set(eg.keys()))
#print list(set(eg.keys()) - set(chado.keys()))
print 'Loading Update file ...'
f = open(args.file, 'w')
for k in chado.keys():
  if (eg.has_key(k)):
    #if (chado[k]['name'] != eg[k]['name'] and chado[k]['name'] != ''):
    if (chado[k]['name'] != eg[k]['name']):
      print 'Name Diff:', k, chado[k]['name'], eg[k]['name']
      f.write('# Name change for ' + k + ' from ' + eg[k]['name'] + ' to ' + chado[k]['name'] + "\n")
      if (eg[k]['name'] != ''):
        f.write('UPDATE gene, xref SET xref.display_label=\'' + chado[k]['name'] + '\' WHERE gene.display_xref_id=xref.xref_id AND gene.stable_id=\'' + k + '\'; # Was ' + eg[k]['name'] + "\n")
      else:
        f.write('INSERT INTO xref (external_db_id, dbprimary_acc, display_label, version, description, info_type) VALUES (50642, \'' + k + '\', \'' + chado[k]['name'] + '\', 0, \'' + k + '\', "DIRECT");' + "\n")
        #f.write('LAST_INSERT_ID();' + "\n")
        #f.write('UPDATE gene, xref SET gene.display_xref_id=LAST_INSERT_ID() WHERE gene.stable_id=\'' + k + '\'; # Was NULL' + "\n")
      
      #print 'UPDATE spombe_eg_gene__translation__main SET display_label_1074=\'' + chado[k]['name'] + '\', display_label_1074_r1=\'' + chado[k]['name'] + '\' WHERE stable_id_1023=\'' + k + '\';'
      #print 'UPDATE spombe_eg_gene__transcript__main SET display_label_1074=\'' + chado[k]['name'] + '\', display_label_1074_r1=\'' + chado[k]['name'] + '\' WHERE stable_id_1023=\'' + k + '\';'
      #print 'UPDATE spombe_eg_gene__ox_pombase_gene__dm SET display_label_1074=\'' + chado[k]['name'] + '\' WHERE dbprimary_acc_1074=\'' + k + '\';'
      #print 'UPDATE spombe_eg_gene__ox_pombase_gene_name__dm SET display_label_1074=\'' + chado[k]['name'] + '\' WHERE dbprimary_acc_1074=\'' + k + '\';'
      #print 'UPDATE spombe_eg_gene__gene__main SET display_label_1074=\'' + chado[k]['name'] + '\' WHERE stable_id_1023=\'' + k + '\';'
    
    setdiff = set(chado[k]['synonyms'])^set(eg[k]['synonyms']) 
    
    if (len(setdiff) > 0):
      #print '# Synonyms for ' + k
      if (chado[k]['name'] != eg[k]['name'] and eg[k]['name'] != '' and chado[k]['name'] in set(eg[k]['synonyms'])):
        f.write('UPDATE gene, xref, external_synonym SET external_synonym.synonym=\'' + eg[k]['name'] + '\' WHERE external_synonym.synonym=\'' + chado[k]['name'] + '\' AND gene.display_xref_id=xref.xref_id AND xref.xref_id=external_synonym.xref_id AND gene.stable_id=\'' + k + '\'; # Was ' + chado[k]['name'] + "\n")
      
      for s in set(chado[k]['synonyms'])-set(eg[k]['synonyms']):
        if ((chado[k]['name'] != eg[k]['name'] and chado[k]['name'] in set(eg[k]['synonyms'])) or s==''):
          continue
        f.write('INSERT INTO external_synonym SELECT xref.xref_id, \'' + s + '\' FROM gene, xref WHERE gene.display_xref_id=xref.xref_id AND gene.stable_id=\'' + k + '\';' + "\n")
      
      for s in set(eg[k]['synonyms'])-set(chado[k]['synonyms']):
        if (s==k or s=='' or (chado[k]['name'] != eg[k]['name'] and chado[k]['name'] in set(eg[k]['synonyms']))):
          continue
        f.write('DELETE external_synonym.* FROM xref JOIN external_synonym ON (xref.xref_id=external_synonym.xref_id) WHERE external_synonym.synonym=\'' + s + '\'  AND gene.stable_id=\'' + k + '\';' + "\n")
      
      #print 'Synonym Diff:', k, '|', chado[k]['name'], eg[k]['name'], '|', chado[k]['synonyms'], eg[k]['synonyms']

      
f.write('UPDATE xref JOIN gene ON (gene.stable_id=xref.dbprimary_acc) SET gene.display_xref_id=xref.xref_id WHERE external_db_id=50642;')

#Make sure that all genes that have a gene name is also reflected in the name of th etranscript
f.write('update gene join transcript using (gene_id) join xref x1 on (gene.display_xref_id=x1.xref_id) join xref x2 on (transcript.display_xref_id=x2.xref_id) set x2.display_label=x1.display_label where x1.dbprimary_acc!=x1.display_label and x1.display_label!=x2.display_label;')

f.close()

