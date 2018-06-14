#!/usr/bin/python

import MySQLdb as mdb
import psycopg2
import psycopg2.extras
import psycopg2.extensions
from psycopg2 import OperationalError
import os
import sys
import pprint
import argparse

con_old = None
con_new = None

old = dict()
new = dict()

parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--new_chado_dbname', help="New chado dump version release number", default='pombase_chado_v42')
parser.add_argument('--old_chado_dbname', help="Old chado dump version release number", default='pombase_chado_v41')
parser.add_argument('--dbchadohost', help="Core database host", default="postgres-eg-pombe.ebi.ac.uk")
parser.add_argument('--dbchadoport', type=int, help="Core database port", default=5432)
parser.add_argument('--dbchadouser', help="Core database username", default="ensrw")
parser.add_argument('--dbchadopass', help="Core database password", default="xxxxx")
args = parser.parse_args()

old_db = args.old_chado_dbname
new_db = args.new_chado_dbname
pghost = args.dbchadohost
pgport = str(args.dbchadoport)
pguser = args.dbchadouser
pgpass = args.dbchadopass


try:
  con_new = psycopg2.connect(host=pghost, port=pgport, user=pguser, password=pgpass, database=new_db)
  cur_new = con_new.cursor()
  
  cur_new.execute("select f.uniquename, count(*) from feature f group by f.uniquename having count(*) > 1;")
  multiple_uniquenames = cur_new.fetchall()
  if len(multiple_uniquenames) > 0:
    if len(multiple_uniquenames) == 1:
      print "There is 1 feature with an identical uniquename."
    else:
      print "There are", len(multiple_uniquenames), "features with identical uniquenames."
    print "Use the following SQL to identify the troublesome uniquenames:"
    print "\tSELECT f.uniquename, COUNT(*) FROM feature f"
    print "\t  GROUP BY f.uniquename HAVING COUNT(*) > 1;"
    quit = 'no'
    quit = raw_input("Continue (default: no) [yes/no]: ")
    if quit == 'no' or quit == '':
      sys.exit("Non-unique feature.uniquenames column")
  
  cur_old.execute("SELECT feature.uniquename, feature.name, t.name, featureloc.fmin, featureloc.fmax FROM feature, cvterm t, featureloc WHERE feature.feature_id=featureloc.feature_id AND feature.type_id=t.cvterm_id;")
  old_rows = cur_old.fetchall()
  cur_old.close()
  
  for old_row in old_rows:
    try:
      cur_new.execute("SELECT feature.uniquename, feature.name, t.name, featureloc.fmin, featureloc.fmax FROM feature, cvterm t, featureloc WHERE feature.feature_id=featureloc.feature_id AND feature.type_id=t.cvterm_id AND feature.uniquename='%s';" % (old_row[0]))
    except Exception, e:
      print "PostgreSQL Error:"
      pprint.pprint(e)
      continue
    new_rows = cur_new.fetchall()
    
    old[old_row[0]] = {'name': old_row[1]}
    
    row_count = 0
    difference = dict()
    for new_row in new_rows:
      row_count+=1
      same_name      = new_row[1] == old_row[1]
      same_type      = new_row[2] == old_row[2]
      same_start     = new_row[3] == old_row[3]
      same_stop      = new_row[4] == old_row[4]
      if same_name and same_type and same_start and same_stop and True:
        continue
      else:
        if difference.has_key(old_row[0]) == False:
          difference[old_row[0]] = []
        changes_to_feature = []
        
        if same_name == False:
          changes_to_feature.append("Name change from %s to %s" % (old_row[1], new_row[1]))
        if same_type == False:
          changes_to_feature.append("Type change from %s to %s" % (old_row[2], new_row[2]))
        if same_start == False:
          changes_to_feature.append("Start change from %d to %d" % (old_row[3], new_row[3]))
        if same_stop == False:
          changes_to_feature.append("Stop change from %d to %d" % (old_row[4], new_row[4]))
        
        difference[old_row[0]].append(changes_to_feature)
    
    if len(new_rows) == 0:
      changes_to_feature = []
      changes_to_feature.append("%s absent in new database" % (old_row[0]))
      if difference.has_key(old_row[0]) == False:
        difference[old_row[0]] = []
      difference[old_row[0]].append(changes_to_feature)
    
    if len(difference) > 0:
      print old_row[0]
      for d in difference[old_row[0]]:
        for dd in d:
          print "\t" + dd
      print "\n============================================================\n"
  
  #cur_new.execute("SELECT feature.uniquename, feature.name, t.name, featureloc.fmin, featureloc.fmax FROM feature, cvterm t, featureloc WHERE feature.feature_id=featureloc.feature_id AND feature.type_id=t.cvterm_id AND (t.name LIKE '%_UTR' OR t.name LIKE '%RNA' OR t.name LIKE 'pseudogen%' OR t.name IN ('gene', 'exon', 'intron'));")
  cur_new.execute("SELECT feature.uniquename, feature.name, t.name, featureloc.fmin, featureloc.fmax FROM feature, cvterm t, featureloc WHERE feature.feature_id=featureloc.feature_id AND feature.type_id=t.cvterm_id;")
  new_rows = cur_new.fetchall()
  cur_new.close()
  
  print "Name Changes for:"
  for new_row in new_rows:
    new[new_row[0]] = {'name': new_row[1]}
    if new_row[0] in old:
      if old[new_row[0]]['name'] != new_row[1]:
        print new_row[0] + ',',
  
  s1 = set(old.keys())
  s2 = set(new.keys())
  print "\n\nRemoved Genes:"
  print s1.difference(s2)
  print "\n\nNew Genes"
  print s2.difference(s1)

except Exception, e:
  print "Error:"
  exc_type, exc_obj, exc_tb = sys.exc_info()
  fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
  print(exc_type, fname, exc_tb.tb_lineno)
  pprint.pprint(e)
finally:    
  if con_old:    
    con_old.close()
  if con_new:    
    con_new.close()
