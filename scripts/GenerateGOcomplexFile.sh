#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

wget -q http://curation.pombase.org/dumps/releases/pombase-chado-v${PB_VERSION}-${PB_RELEASE}/pombe-embl/supporting_files/Complex_annotation_filters -O Complex_annotation_filters
sed -i 's/GO:/"GO:/g' Complex_annotation_filters
sed -i 's/$/"/g' Complex_annotation_filters
terms=$(tr '\n' ',' < Complex_annotation_filters | sed 's/,$//g')

mysql -u$DBAMIGOUSER -p$DBAMIGOPASS -h$DBAMIGOHOST -P$DBAMIGOPORT $DBAMIGONAME -e "SELECT DISTINCT t.acc, t.name AS GO_name, t.systematic_id, t.symbol, t.full_name AS gene_product_description, CASE WHEN t.IDA>0 THEN 'IDA' WHEN t.IPI>0 THEN 'IPI' WHEN t.IGI>0 THEN 'IGI' WHEN t.IC>0 THEN 'IC' WHEN t.TAS>0 THEN 'TAS' WHEN t.ISO>0 THEN 'ISO' WHEN t.ISS>0 THEN 'ISS' WHEN t.IEA>0 THEN 'IEA' WHEN t.NAS>0 THEN 'NAS' ELSE t.code END AS evidence_code, CASE WHEN t.IDA>0 THEN t.IDA_source WHEN t.IPI>0 THEN t.IPI_source WHEN t.IGI>0 THEN t.IGI_source WHEN t.IC>0 THEN t.IC_source WHEN t.TAS>0 THEN t.TAS_source WHEN t.ISO>0 THEN t.ISO_source WHEN t.ISS>0 THEN t.ISS_source WHEN t.IEA>0 THEN t.IEA_source WHEN t.NAS>0 THEN t.NAS_source ELSE t.source END AS source, CASE WHEN t.IDA>0 THEN t.IDA_assigned_by WHEN t.IPI>0 THEN t.IPI_assigned_by WHEN t.IGI>0 THEN t.IGI_assigned_by WHEN t.IC>0 THEN t.IC_assigned_by WHEN t.TAS>0 THEN t.TAS_assigned_by WHEN t.ISO>0 THEN t.ISO_assigned_by WHEN t.ISS>0 THEN t.ISS_assigned_by WHEN t.IEA>0 THEN t.IEA_assigned_by WHEN t.NAS>0 THEN t.NAS_assigned_by ELSE t.assigned_by END AS assigned_by FROM ( SELECT DISTINCT t1.acc AS acc, t1.name AS name, t2.systematic_id AS systematic_id, t2.symbol AS symbol, t2.full_name AS full_name, GROUP_CONCAT(DISTINCT t2.code) AS code, GROUP_CONCAT(DISTINCT t2.source) AS source, GROUP_CONCAT(DISTINCT t2.assigned_by) AS assigned_by, SUM( CASE WHEN t2.code='EXP' THEN 1 ELSE 0 END ) as EXP, SUM( CASE WHEN t2.code='IC' THEN 1 ELSE 0 END ) as IC, SUM( CASE WHEN t2.code='IDA' THEN 1 ELSE 0 END ) as IDA, SUM( CASE WHEN t2.code='IEA' THEN 1 ELSE 0 END ) as IEA, SUM( CASE WHEN t2.code='IEP' THEN 1 ELSE 0 END ) as IEP, SUM( CASE WHEN t2.code='IGI' THEN 1 ELSE 0 END ) as IGI, SUM( CASE WHEN t2.code='IKR' THEN 1 ELSE 0 END ) as IKR, SUM( CASE WHEN t2.code='IMP' THEN 1 ELSE 0 END ) as IMP, SUM( CASE WHEN t2.code='IPI' THEN 1 ELSE 0 END ) as IPI, SUM( CASE WHEN t2.code='ISM' THEN 1 ELSE 0 END ) as ISM, SUM( CASE WHEN t2.code='ISO' THEN 1 ELSE 0 END ) as ISO, SUM( CASE WHEN t2.code='ISS' THEN 1 ELSE 0 END ) as ISS, SUM( CASE WHEN t2.code='NAS' THEN 1 ELSE 0 END ) as NAS, SUM( CASE WHEN t2.code='ND' THEN 1 ELSE 0 END ) as ND, SUM( CASE WHEN t2.code='RCA' THEN 1 ELSE 0 END ) as RCA, SUM( CASE WHEN t2.code='TAS' THEN 1 ELSE 0 END ) as TAS, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='EXP' THEN t2.source ELSE NULL END ) as EXP_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IC' THEN t2.source ELSE NULL END ) as IC_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IDA' THEN t2.source ELSE NULL END ) as IDA_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IEA' THEN t2.source ELSE NULL END ) as IEA_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IEP' THEN t2.source ELSE NULL END ) as IEP_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IGI' THEN t2.source ELSE NULL END ) as IGI_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IKR' THEN t2.source ELSE NULL END ) as IKR_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IMP' THEN t2.source ELSE NULL END ) as IMP_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IPI' THEN t2.source ELSE NULL END ) as IPI_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ISM' THEN t2.source ELSE NULL END ) as ISM_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ISO' THEN t2.source ELSE NULL END ) as ISO_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ISS' THEN t2.source ELSE NULL END ) as ISS_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='NAS' THEN t2.source ELSE NULL END ) as NAS_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ND' THEN t2.source ELSE NULL END ) as ND_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='RCA' THEN t2.source ELSE NULL END ) as RCA_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='TAS' THEN t2.source ELSE NULL END ) as TAS_source, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='EXP' THEN t2.assigned_by ELSE NULL END ) as EXP_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IC' THEN t2.assigned_by ELSE NULL END ) as IC_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IDA' THEN t2.assigned_by ELSE NULL END ) as IDA_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IEA' THEN t2.assigned_by ELSE NULL END ) as IEA_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IEP' THEN t2.assigned_by ELSE NULL END ) as IEP_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IGI' THEN t2.assigned_by ELSE NULL END ) as IGI_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IKR' THEN t2.assigned_by ELSE NULL END ) as IKR_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IMP' THEN t2.assigned_by ELSE NULL END ) as IMP_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='IPI' THEN t2.assigned_by ELSE NULL END ) as IPI_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ISM' THEN t2.assigned_by ELSE NULL END ) as ISM_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ISO' THEN t2.assigned_by ELSE NULL END ) as ISO_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ISS' THEN t2.assigned_by ELSE NULL END ) as ISS_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='NAS' THEN t2.assigned_by ELSE NULL END ) as NAS_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='ND' THEN t2.assigned_by ELSE NULL END ) as ND_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='RCA' THEN t2.assigned_by ELSE NULL END ) as RCA_assigned_by, GROUP_CONCAT( DISTINCT CASE WHEN t2.code='TAS' THEN t2.assigned_by ELSE NULL END ) as TAS_assigned_by FROM ( SELECT acl.term2_id, t.acc, t.name FROM term AS cc JOIN graph_path AS tcl ON cc.id = tcl.term1_id JOIN graph_path AS acl ON tcl.term2_id = acl.term1_id JOIN term AS t ON t.id=acl.term1_id WHERE cc.name='macromolecular complex' ) AS t1 JOIN ( SELECT association.term_id, dbx1.xref_key as systematic_id, gene_product.symbol, gene_product.full_name, evidence.code, CONCAT_WS(':', dbx2.xref_dbname, dbx2.xref_key) AS source, dbx1.xref_dbname, db.name as assigned_by FROM gene_product JOIN species ON gene_product.species_id = species.id JOIN association ON association.gene_product_id = gene_product.id JOIN evidence ON evidence.association_id = association.id JOIN dbxref AS dbx1 ON dbx1.id = gene_product.dbxref_id JOIN dbxref AS dbx2 ON dbx2.id = evidence.dbxref_id JOIN db ON association.source_db_id=db.id WHERE species.genus = 'Schizosaccharomyces' AND species.species = 'pombe' ) AS t2 ON (t1.term2_id=t2.term_id) WHERE t1.acc NOT IN (${terms}) AND t2.code NOT IN ('IGI') GROUP BY t1.acc, t2.systematic_id ORDER BY t1.acc, t2.systematic_id ) AS t;" > Complex_annotation