#!/usr/bin/python

import MySQLdb as mdb
import re
import sys
import argparse

parser = argparse.ArgumentParser(description='List all of the species in a given release of a division.')
parser.add_argument('--division', help="EG Division (eg EnsemblFungi)", default="EnsemblFungi")
parser.add_argument('--eg_release', type=int, help="EG release version (eg 18)", default=18)
parser.add_argument('--e_release', type=int, help="Ensembl release version (eg 71)", default=71)
parser.add_argument('--dbhost', help="Core database host", default="mysql.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=1234)
parser.add_argument('--dbuser', help="Core database username", default='')
parser.add_argument('--dbpass', help="Core database password", default='')
args = parser.parse_args()

con = None

division = args.division
dbhost = args.dbhost
dbport = args.dbport
dbuser = args.dbuser
dbpswd = args.dbpass


associated_xref_spp = []

try:
  con = mdb.connect(host=dbhost, port=dbport, user=dbuser, passwd=dbpswd)
  cur = con.cursor();
  
  for dbtype in ['core', 'otherfeatures', 'variation', 'funcgen']:
    print "Looking for", dbtype,"databases:"
    cur.execute("SHOW DATABASES like '%_" + dbtype + "_%'")
    rows = cur.fetchall()
    for row in rows:
      core_db = re.sub(dbtype, 'core', row[0])
      if re.match('master_schema', core_db):
        continue 
      cur.execute("SHOW TABLES FROM " + row[0] + " LIKE 'meta';")
      rows = cur.fetchall();
      if len(rows) == 0:
        continue
      cur.execute("SELECT meta_value FROM " + row[0] + ".meta where meta_key='species.division';");
      core_division = cur.fetchone()
      # print core_division
      if core_division != None and core_division[0] == division:
        #spp = row[0].split('_' + dbtype)
        #print spp[0]
        print "\t" + row[0]
        #cur.execute("SELECT MAX(ABS(seq_region_end-seq_region_start)) FROM " + row[0] + ".gene")
        #maxGeneSize = cur.fetchone()
        #print "\tMax Gene Size:", maxGeneSize[0]
        
        if dbtype == 'core':
          cur.execute("SELECT count(*) FROM " + row[0] + ".associated_xref;");
          assoc_xref_count = cur.fetchone()
          if assoc_xref_count[0] > 0:
            associated_xref_spp.append(row[0])
    
    if dbtype == 'core' and len(associated_xref_spp) > 0:
      print "The following spp have associated_xrefs:"
      for spp in associated_xref_spp:
        print "\t" + spp
  
  
except mdb.Error, e:
  print "Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)

finally:    
  if con:    
    con.close()


