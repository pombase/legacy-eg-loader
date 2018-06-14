#!/usr/bin/python

import MySQLdb as mdb
import sys

conm = None

print args.dbhost, args.dbport, sppdb
try:
  conm = mdb.connect(host=args.dbhost, port=args.dbport, user='ensro', db=sppdb)
  cur = conm.cursor()
  
  fi = open('data/picr/pdb2UniParc.tsv')
  for line in fi:
    line = line.rstrip()
    p2up = line.split("\t")
    ups = p2up[1].split("|")
    for up in ups:
      cur.execute("select * from object_xref join xref using (xref_id) where dbprimary_acc=%s;", (up))
      row = cur.fetchone()
      print "INSERT INTO xref "
  
  cur.execute("SELECT gene.stable_id, description, status FROM gene;")
  rows = cur.fetchall()
  cur.close()
  for row in rows:
    stable_id = row[0]
    description = re.sub('\'','\\\'', row[1])
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
