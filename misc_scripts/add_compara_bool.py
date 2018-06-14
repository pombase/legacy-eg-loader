#!/usr/bin/python

import MySQLdb as mdb
import sys
import argparse
from sets import Set

specieslist = Set(['aclavatus', 'aflavus', 'afumigatus', 'afumigatusa1163',
'agossypii', 'anidulans', 'aniger', 'aoryzae', 'aterreus', 'bcinerea',
'bgraminis', 'cgloeosporioides', 'cgraminicola', 'chigginsianum',
'cneoformans', 'corbiculare', 'dseptosporum', 'ffujikuroi', 'fgraminearum',
'foxysporum', 'fpseudograminearum', 'fsolani', 'fverticillioides', 'ggraminis',
'kpastoris', 'lmaculans', 'mlaricipopulina', 'moryzae', 'mpoae', 'mviolaceum',
'ncrassa', 'nfischeri', 'pgraminis', 'pgraminisug99', 'pnodorum', 'pteres',
'ptriticina', 'ptriticirepentis', 'scerevisiae', 'scryophilus', 'sjaponicus',
'soctosporus', 'spombe', 'sreilianum', 'ssclerotiorum', 'tmelanosporum',
'treesei', 'tvirens', 'umaydis', 'vdahliae', 'vdahliaejr2', 'ylipolytica',
'ztritici'])


parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--division', help="Division (eg fungi)", default='fungi')
parser.add_argument('--eg_release', type=int, help="EG release version (eg 18)", default=21)
parser.add_argument('--dbhost', help="Core database host", default="mysql-eg-pombe.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=4348)
parser.add_argument('--dbpass', help="Core database port", default='xxxxx')
args = parser.parse_args()

eg_release    = args.eg_release # 20
martdb = args.division + "_mart_" + str(eg_release)

conp = None
conm = None

tbl2col = dict()

try:
  conm = mdb.connect(host=args.dbhost, port=args.dbport, user='ensrw', passwd=args.dbpass, db=martdb)
  cur = conm.cursor()
  for spp in specieslist:
    print spp
    print "  Creating homo_TEMP table ..."
    cur.execute("create table homo_TEMP as select a.gene_id_1020_key from spombe_eg_gene__homolog_%s_eg__dm b, spombe_eg_gene__gene__main a where a.gene_id_1020_key=b.gene_id_1020_key and not (b.chr_name_4016_r2 is null and b.stable_id_4016_r3 is null and b.perc_id_4015_r1 is null and b.stable_id_4016_r2 is null and b.ds_4014 is null and b.chr_start_4016_r2 is null and b.perc_id_4015 is null and b.description_4014 is null and b.chr_end_4016_r2 is null and b.stable_id_4016_r1 is null and b.dn_4014 is null);" % (spp))
    
    print "  Updating genomic feature tables ..."
    cur.execute("alter table spombe_eg_gene__gene__main add column homolog_%s_eg_bool int(11);" % (spp))
    cur.execute("alter table spombe_eg_gene__transcript__main add column homolog_%s_eg_bool int(11);" % (spp))
    cur.execute("alter table spombe_eg_gene__translation__main add column homolog_%s_eg_bool int(11);" % (spp))
    cur.execute("update spombe_eg_gene__gene__main a join homo_TEMP using (gene_id_1020_key) set homolog_%s_eg_bool=1;" % (spp))
    cur.execute("update spombe_eg_gene__transcript__main a join homo_TEMP using (gene_id_1020_key) set homolog_%s_eg_bool=1;" % (spp))
    cur.execute("update spombe_eg_gene__translation__main a join homo_TEMP using (gene_id_1020_key) set homolog_%s_eg_bool=1;" % (spp))
    
    cur.execute("drop table homo_TEMP;")
  
  print "  Creating para_TEMP table ..."
  cur.execute("create table para_TEMP as select a.gene_id_1020_key from spombe_eg_gene__paralog_%s_eg__dm b, spombe_eg_gene__gene__main a where a.gene_id_1020_key=b.gene_id_1020_key and not (b.chr_name_4016_r2 is null and b.stable_id_4016 is null and b.stable_id_4016_r3 is null and b.perc_cov_4015_r1 is null and b.perc_id_4015_r1 is null and b.stable_id_4016_r2 is null and b.ds_4014 is null and b.chr_start_4016_r2 is null and b.perc_id_4015 is null and b.chr_end_4016_r2 is null and b.perc_cov_4015 is null and b.stable_id_4016_r1 is null and b.dn_4014 is null);" % ('spombe'))

  print "spombe"
  print "  Updating genomic feature tables ..."
  cur.execute("update spombe_eg_gene__gene__main a join para_TEMP using (gene_id_1020_key) set paralog_%s_eg_bool=1;" % ('spombe'))
  cur.execute("update spombe_eg_gene__transcript__main a join para_TEMP using (gene_id_1020_key) set paralog_%s_eg_bool=1;" % ('spombe'))
  cur.execute("update spombe_eg_gene__translation__main a join para_TEMP using (gene_id_1020_key) set paralog_%s_eg_bool=1;" % ('spombe'))
  cur.execute("drop table para_TEMP;")
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  if conm:    
    conm.close()
