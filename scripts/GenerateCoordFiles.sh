#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "select gene.stable_id, IF(e1.seq_region_strand=1, (e1.seq_region_start+t.seq_start-1), (e2.seq_region_end-t.seq_end+1)) cds_start, IF(e1.seq_region_strand=1, (e2.seq_region_start+t.seq_end-1), (e1.seq_region_end-t.seq_start+1)) cds_end, e2.seq_region_strand from gene join seq_region on (gene.seq_region_id=seq_region.seq_region_id) join transcript on (gene.gene_id=transcript.gene_id) join translation t on (transcript.transcript_id=t.transcript_id) join exon e1 on (t.start_exon_id=e1.exon_id) join exon e2 on (t.end_exon_id=e2.exon_id) where gene.biotype='protein_coding' and seq_region.name='I'" > chromosome1.cds.coords

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "select gene.stable_id, exon.seq_region_start, exon.seq_region_end, exon.seq_region_strand from gene join transcript on (gene.gene_id=transcript.gene_id) join exon_transcript on (transcript.transcript_id=exon_transcript.transcript_id) join exon on (exon_transcript.exon_id=exon.exon_id) join seq_region on (exon.seq_region_id=seq_region.seq_region_id) where seq_region.name='I' order by exon.seq_region_start, exon_transcript.rank" > chromosome1.exon.coords

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "select gene.stable_id, IF(e1.seq_region_strand=1, (e1.seq_region_start+t.seq_start-1), (e2.seq_region_end-t.seq_end+1)) cds_start, IF(e1.seq_region_strand=1, (e2.seq_region_start+t.seq_end-1), (e1.seq_region_end-t.seq_start+1)) cds_end, e2.seq_region_strand from gene join seq_region on (gene.seq_region_id=seq_region.seq_region_id) join transcript on (gene.gene_id=transcript.gene_id) join translation t on (transcript.transcript_id=t.transcript_id) join exon e1 on (t.start_exon_id=e1.exon_id) join exon e2 on (t.end_exon_id=e2.exon_id) where gene.biotype='protein_coding' and seq_region.name='II'" > chromosome2.cds.coords

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "select gene.stable_id, exon.seq_region_start, exon.seq_region_end, exon.seq_region_strand from gene join transcript on (gene.gene_id=transcript.gene_id) join exon_transcript on (transcript.transcript_id=exon_transcript.transcript_id) join exon on (exon_transcript.exon_id=exon.exon_id) join seq_region on (exon.seq_region_id=seq_region.seq_region_id) where seq_region.name='II' order by exon.seq_region_start, exon_transcript.rank" > chromosome2.exon.coords

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "select gene.stable_id, IF(e1.seq_region_strand=1, (e1.seq_region_start+t.seq_start-1), (e2.seq_region_end-t.seq_end+1)) cds_start, IF(e1.seq_region_strand=1, (e2.seq_region_start+t.seq_end-1), (e1.seq_region_end-t.seq_start+1)) cds_end, e2.seq_region_strand from gene join seq_region on (gene.seq_region_id=seq_region.seq_region_id) join transcript on (gene.gene_id=transcript.gene_id) join translation t on (transcript.transcript_id=t.transcript_id) join exon e1 on (t.start_exon_id=e1.exon_id) join exon e2 on (t.end_exon_id=e2.exon_id) where gene.biotype='protein_coding' and seq_region.name='III'" > chromosome3.cds.coords

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "select gene.stable_id, exon.seq_region_start, exon.seq_region_end, exon.seq_region_strand from gene join transcript on (gene.gene_id=transcript.gene_id) join exon_transcript on (transcript.transcript_id=exon_transcript.transcript_id) join exon on (exon_transcript.exon_id=exon.exon_id) join seq_region on (exon.seq_region_id=seq_region.seq_region_id) where seq_region.name='III' order by exon.seq_region_start, exon_transcript.rank" > chromosome3.exon.coords
