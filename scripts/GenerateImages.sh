#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

gid=$(sed -n ${LSB_JOBINDEX}p ../data/tmp/batch_GeneImages.csv)

# Use this for testing
#gid=$(sed -n 1p ../data/tmp/batch_GeneImages.csv)

# Use this to pic up the erroneous images
#gid=$(sed -n ${LSB_JOBINDEX}p ../data/tmp/missingImages.csv)

cd ../data/images
imgdir=`pwd`

for g in ${gid}
do
  echo $g
  cid=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select seq_region.name from seq_region join gene on (seq_region.seq_region_id=gene.seq_region_id) where gene.stable_id='${g}';"`
  cd $imgdir/${cid}
  
  i=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select CONCAT_WS('-',FLOOR(if(gid.start<0, 0, if(gid.end>gid.length, if(gid.length<15000, 0, gid.end-15000), gid.start))), CEILING(if(gid.start<0, if(gid.length<15000, gid.length, 15000), if(gid.end>gid.length, gid.length, gid.end)))) from (select seq_region.length, gene.seq_region_start+((gene.seq_region_end-gene.seq_region_start)/2)-7500 as start, gene.seq_region_start+((gene.seq_region_end-gene.seq_region_start)/2)+7500 as end from gene join seq_region on (gene.seq_region_id=seq_region.seq_region_id) where gene.stable_id='${g}') gid;"`
  
  wget "http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/Component/Location/Web/ViewBottom?export=png;g=${g};t=${t};r=${cid}:${i};db=core;i_width=700" -O ${g}_gene.png -t 5
  #echo "http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/Component/Location/Web/ViewBottom?export=png;g=${g};t=${t};r=${cid}:${i};db=core;i_width=700"
  
  tid=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select transcript.stable_id from gene join transcript on (gene.gene_id=transcript.gene_id) where gene.stable_id='${g}';"`
  for t in ${tid}
  do
    wget "http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/Component/Transcript/Web/TranscriptImage?export=png;g=$g;t=${t};db=core;i_width=700" -O ${t}_trans.png -t 5
    #echo "http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/Component/Transcript/Web/TranscriptImage?export=png;g=$g;t=${t};db=core;i_width=700"
    
    pep=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select count(*) from transcript join translation on (transcript.transcript_id=translation.transcript_id) where transcript.stable_id='${t}';")
    if [ $pep -gt 0 ]
    then
      wget "http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/Component/Transcript/Web/TranslationImage?export=png;g=${g};t=${t};db=core;i_width=700" -O ${t}_pep.png -t 5
      #echo "http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/Component/Transcript/Web/TranslationImage?export=png;g=${g};t=${t};db=core;i_width=700"
    fi
  done
done
