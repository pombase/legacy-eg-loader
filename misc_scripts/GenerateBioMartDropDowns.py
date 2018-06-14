#!/usr/bin/python

import MySQLdb as mdb
import psycopg2
import psycopg2.extras
import psycopg2.extensions
from psycopg2 import OperationalError
import sys
import argparse
from sets import Set
import json
import pprint

parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--division', help="The EG division (eg EnsemblFungi)", default="EnsemblFungi")
parser.add_argument('--eg_release', type=int, help="EG release version (eg 21)", default=21)
parser.add_argument('--chado_release', type=int, help='Chado DB Dump version (eg 41)', default=41)
parser.add_argument('--dbhost', help="Core database host", default="mysql-eg-pombe.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=4348)
parser.add_argument('--dbchadohost', help="Chado database host", default="ensrw")
parser.add_argument('--dbchadoport', help="Chado database port", default="ensrw")
parser.add_argument('--dbchadouser', help="Chado database username", default="ensrw")
parser.add_argument('--dbchadopass', help="Chado database password", default="xxxxx")
parser.add_argument('--file', help="Output file. Default is 'data/sql/update_ontology.sql'", default="data/sql/update_gene_names_synonyms.sql")
args = parser.parse_args()

division_long = args.division      # 'EnsemblFungi'
eg_release    = args.eg_release    # 18
chado_release = args.chado_release # 37

pghost = args.dbchadohost
pgport = str(args.dbchadoport)
pguser = args.dbchadouser
pgpass = args.dbchadopass

division = division_long.replace('Ensembl', '')
division = division.lower()
martdb = division + "_mart_" + str(eg_release)

conp = None
conm = None

tbl2col = dict()

rejectlist = Set(['object_xref_id', 'transcript_id_1064_key', 'source', 'group_id', 'group_des', 'subject'])

print args.dbhost, args.dbport, division


def get_allele(allele_id):
  try:
    con_pg = psycopg2.connect(host=pghost, port=pgport, user=pguser, password=pgpass, database='pombase_chado_v'+str(chado_release))
    cur_pg = con_pg.cursor()
    cur_pg.execute("SELECT subject.name, subject.uniquename, object.name, object.uniquename FROM feature subject, feature object, feature_relationship fr WHERE fr.subject_id=subject.feature_id and fr.object_id=object.feature_id and subject.uniquename='%s';" % allele_id)
    rows = cur_pg.fetchall()
    if (allele_id == 'SPAC222.11:allele-1' or allele_id == 'SPAC16.01:allele-5'):
      print rows
      alleleOf = rows[0]
      print "" + allele_id + " [" + str(alleleOf[0]) + "]" + " allele of " + str(alleleOf[3]) + " [" + str(alleleOf[2]) + "]"
    #print rows 
    if ( len(rows) == 0 or len(rows) > 1 ):
      #print allele_id
      return allele_id
    alleleOf = rows[0]
#    if (allele_id == 'SPAC16.01:allele-1' or allele_id == 'SPAC16.01:allele-2' or allele_id == 'SPAC16.01:allele-3' or allele_id == 'SPAC16.01:allele-4' or allele_id == 'SPAC16.01:allele-5'):
#      print allele_id + " [" + str(alleleOf[0]) + "]" + " allele of " + str(alleleOf[3]) + " [" + str(alleleOf[2]) + "]"
#      print alleleOf
#      #print alleleOf[2]
#      #print alleleOf[3]
    display_label = "" + allele_id + " [" + str(alleleOf[0]) + "]" + " allele of " + str(alleleOf[3]) + " [" + str(alleleOf[2]) + "]"
    #print display_label
    return display_label 
  except Exception, e:
    print "Allele Error:"
    pprint.pprint(e)
  finally:    
    if con_pg:    
      con_pg.close()
  return allele_id




try:
  conm = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro', db=martdb)
  cur = conm.cursor()
  cur.execute("SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='%s' AND TABLE_NAME like '%s';" % (martdb, '%_extension_%'))
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    col_name = row[1]
    col_name = col_name.replace('_acc', '')
    col_name = col_name.replace('_label', '')
    col_name = col_name.replace('_db', '')
    
    if (col_name not in rejectlist):
      if (tbl2col.has_key(row[0])):
        tbl2col[row[0]].append(col_name)
      else:
        tbl2col[row[0]] = [col_name]
  
  json_array = dict()
  cur = conm.cursor()
  f = open(args.file, 'w')
  for k in tbl2col.keys():
    print "Identifying distinct values for columns in " + k
    if (json_array.has_key(k) is False):
      json_array[k] = dict()
    for c in Set(tbl2col[k]):
      sql = "SELECT distinct " + c + "_acc, " + c + "_label FROM " + k + ";"
      cur.execute(sql)
      json_array[k][c] = []
      for v in cur.fetchall():
        if ( c == 'allele' ):
#          if ( v[0] == 'SPAC16.01:allele-1' or v[0] == 'SPAC16.01:allele-2' or v[0] == 'SPAC16.01:allele-3' or v[0] == 'SPAC16.01:allele-4' or v[0] == 'SPAC16.01:allele-5' ):
#            print '==========================================================='
#            print v
          #print k, c, str(v[0])
          f.write(k + "\t" + c + "\t" + str(v[1]) + "\t" + str(get_allele(v[0])) + "\n")
        else :
          #print k, c, str(v[0])  
          if ( v[0] == v[1] ):
            f.write(k + "\t" + c + "\t" + str(v[0]) + "\t" + str(v[1]) + "\n")
          else:
            f.write(k + "\t" + c + "\t" + str(v[0]) + "\t[" + str(v[0]) + "] " + str(v[1]) + "\n")
        json_array[k][c].append(v[0])
  
  cur.close()
  
  f.close()  
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  if conm:    
    conm.close()

