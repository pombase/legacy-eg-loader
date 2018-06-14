#!/usr/bin/python

import MySQLdb as mdb
import sys
import argparse

parser = argparse.ArgumentParser(description='Generate an SQL file to update the start and end exon phases in the core database.')
parser.add_argument('--species', help="The dataset species name (eg schizosaccharomyces_pombe)", default="schizosaccharomyces_pombe")
parser.add_argument('--eg_release', type=int, help="EG release version (eg 18)", default=18)
parser.add_argument('--e_release', type=int, help="Ensembl release version (eg 71)", default=71)
parser.add_argument('--assembly', type=int, help="Species assembly (eg 2)", default=2)
parser.add_argument('--dbhost', help="Core database host", default="mysql.ebi.ac.uk")
parser.add_argument('--dbport', type=int, help="Core database port", default=1234)
parser.add_argument('--dbuser', help="Core database username", default='')
parser.add_argument('--dbpass', help="Core database password", default='')
parser.add_argument('--file', help="Output file. Default is 'data/sql/update_gene_descriptions.sql'", default="data/sql/update_gene_exon_phase.sql")
args = parser.parse_args()

species       = args.species    # 'schizosaccharomyces_pombe'
eg_release    = args.eg_release # 18
e_release     = args.e_release  # 71
assembly      = args.assembly   # 2

sppdb = species + "_core_" + str(eg_release) + "_" + str(e_release) + "_" + str(assembly)

dbhost = args.dbhost
dbport = args.dbport
dbuser = args.dbuser
dbpswd = args.dbpass

transcripts = []

try:
  con = mdb.connect(host=dbhost, port=dbport, user=dbuser, passwd=dbpswd, db=sppdb)
  cur = con.cursor()
  # 
  # General Test
  # 
  #cur.execute("select stable_id from transcript where transcript.stable_id like 'SPAC17H9.20%' or transcript.stable_id like 'SPBC29A3.14c%' or transcript.stable_id like 'SPBC14C8.10%' or transcript.stable_id like 'SPBC16H5.13%' or transcript.stable_id like 'SPBC365.06%' or transcript.stable_id like 'SPBC36B7.08c%';")
  
  #
  # Specific 3' test
  #
  #cur.execute("select stable_id from transcript where transcript.stable_id in ('SPAC110.05.1');")
  #cur.execute("select stable_id from transcript where transcript.stable_id in ('SPAC110.05.1', 'SPAC144.08.1', 'SPAC20H4.04.1', 'SPAC22E12.06c.1', 'SPAC3F10.04.1', 'SPAC806.05.1', 'SPBC16C6.01c.1', 'SPBC1734.07c.1', 'SPBC1E8.02.1', 'SPBC4F6.16c.1', 'SPBC646.12c.1', 'SPBC902.06.1', 'SPBP22H7.04.1', 'SPBP35G2.02.1', 'SPBP8B7.12c.1', 'SPCC1223.12c.1', 'SPCC663.04.1', 'SPCC830.09c.1', 'SPCPB16A4.07.1');")
  
  
  #
  # Final Run
  #
  cur.execute("select stable_id from transcript;")
  
  
  rows = cur.fetchall()
  f = open(args.file, 'w')
  for row in rows:
    transcripts.append(row[0])
    #print row[0]
    cur.execute("select translation.stable_id, exon.stable_id, translation.seq_start, translation.seq_end, exon_transcript.rank, exon.seq_region_start, exon.seq_region_end, exon.seq_region_strand, exon.phase, exon.end_phase, if(translation.start_exon_id=exon.exon_id, 1, 0) startExon, if(translation.end_exon_id=exon.exon_id, 1, 0) endExon from translation join transcript on (translation.transcript_id=transcript.transcript_id) join exon_transcript on (transcript.transcript_id=exon_transcript.transcript_id) join exon on (exon_transcript.exon_id=exon.exon_id) where exon.stable_id like '%s%%' order by rank;" % (row[0]))
    exons = cur.fetchall()
    utr_exon = True
    runningLength = 0
    previousEndPhase = 0
    
    # if(exon_transcript.rank=1, (exon.seq_region_end-exon.seq_region_start+1)-translation.seq_start+1, 0)%3
    
    for exon in exons:
      oldLength = runningLength
      if exon[10] == 1:
        runningLength = exon[6]-exon[5]-exon[2]+2
        utr_exon = False
        if exon[11] == 1:
          utr_exon = True
      elif exon[11] == 1:
        utr_exon = True
      elif utr_exon == False:
        runningLength += exon[6]-exon[5]+1
      elif exon[4] == len(exons) and utr_exon == False:
        runningLength += exon[3]-(exon[6]-exon[5]+1)
        utr_exon = True
      else:
        #print exon[1], exon[5], exon[6], '<====== UTR Exon'
        continue
      
      #if exon[4] == len(exons):
      #  runningLength += exon[3]-(exon[6]-exon[5]+1)
      
      #print exon[1], exon[5], exon[6], runningLength-oldLength, runningLength, previousEndPhase, runningLength%3
      #print "UPDATE exon SET phase=" + str(previousEndPhase) + ", end_phase=" + str(runningLength%3) + " WHERE exon.stable_id='" + exon[1] + "';"
      f.write("UPDATE exon SET phase=" + str(previousEndPhase) + ", end_phase=" + str(runningLength%3) + " WHERE exon.stable_id='" + exon[1] + "';\n")
      
      previousEndPhase = runningLength%3
  f.close()
  cur.close()
  
except mdb.Error, e:
  print "MySQL Error %d: %s" % (e.args[0],e.args[1])
  sys.exit(1)
finally:    
  try:
    con.close()
  except:
    print "No connection handle left when finishing"
  try:
    f.close()
  except:
    print "No file handle left when finishing"


