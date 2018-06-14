#!/usr/bin/python

import argparse
import MySQLdb as mdb
import re
import sys
import types

spp_con = None
pan_con = None

parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--division', help="The EG division (eg EnsemblFungi)", default="EnsemblFungi")
parser.add_argument('--species', help="The dataset species name (eg schizosaccharomyces_pombe)", default="schizosaccharomyces_pombe")
parser.add_argument('--eg_release', type=int, help="EG release version (eg 18)", default=18)
parser.add_argument('--e_release', type=int, help="Ensembl release version (eg 71)", default=71)
parser.add_argument('--assembly', type=int, help="Species assembly (eg 2)", default=2)
parser.add_argument('--dbhost', help="Core database host", default="mysql-cluster-eg-prod-3.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=4243)
parser.add_argument('--file', help="Output file. Default is 'data/sql/update_ontology.sql'", default="data/sql/update_ontology.sql")
args = parser.parse_args()

division   = args.division   # 'EnsemblFungi'
updatedb   = False
species    = args.species    # 'schizosaccharomyces_pombe'
eg_release = args.eg_release # 18
e_release  = args.e_release  # 71
assembly   = args.assembly   # 2

sppdb = species + "_core_" + str(eg_release) + "_" + str(e_release) + "_" + str(assembly)
ontdb = "ensemblgenomes_ontology_" + str(eg_release) + "_" + str(e_release)

ont_list = ['GO', 'SO', 'FYPO', 'MOD', 'PECO']
f = open(args.file, 'w')

try:
  spp_con = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro')
  ont_con = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro')
  spp_cur = spp_con.cursor();
  ont_cur = ont_con.cursor();
  
  
  for ont in ont_list:
    spp_cur.execute("SELECT xref.xref_id, xref.dbprimary_acc, xref.display_label, xref.description FROM " + sppdb + ".xref, " + sppdb + ".external_db WHERE xref.external_db_id=external_db.external_db_id and external_db.db_name='" + ont + "' and xref.dbprimary_acc like '" + ont + ":%'")
    ont_rows = spp_cur.fetchall()
    
    for row in ont_rows:
      ont_cur.execute("SELECT term.name  FROM " + ontdb + ".term, " + ontdb + ".ontology WHERE ontology.ontology_id=term.ontology_id and term.accession='" + row[1] + "' and ontology.name='" + ont + "';")
      new_name = ont_cur.fetchone()
      
      if isinstance(new_name, types.NoneType):
        continue
      
      if row[3] != new_name[0]:
        s = str("UPDATE xref SET display_label='" + row[1] + "', description='" + new_name[0] + "' WHERE xref_id='" + str(row[0]) + "'; # " + row[1] + " was '" + row[3] + "';\n")
        f.write(s)
        #print "UPDATE xref SET display_label='" + new_name[0] + "' WHERE xref_id='" + str(row[0]) + "'; # " + row[1] + " was '" + row[3] + "'"
  
except mdb.Error, e:
  print "Error %d: %s" % (e.args[0],e.args[1])
  f.close()
  sys.exit(1)

finally:    
  f.close()
  if spp_con:
    spp_con.close()
  if ont_con:
    ont_con.close()


