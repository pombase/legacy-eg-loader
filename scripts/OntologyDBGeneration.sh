#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/ontology
cd ../data/ontology

# Get all OBO files that are usually downloaded
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/mini-ontologies/fypo_extension.obo"
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/mini-ontologies/quiescence.obo" -O PBQ.obo
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE/ontologies/go.obo"
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE/ontologies/fypo-simple.obo" -O fypo.obo
#wget "http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology.1_2.obo"
wget "http://sourceforge.net/p/song/svn/HEAD/tree/trunk/so-xp.obo?format=raw" -O so.obo
wget "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/OBO_format/plant_ontology.obo?view=co" -O po.obo
wget "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/collaborators_ontology/gramene/temporal_gramene.obo?view=co" -O temporal_gramene.obo
wget "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/collaborators_ontology/gramene/taxonomy/GR_tax-ontology.obo?view=co" -O GR_tax-ontology.obo
wget "http://obo.cvs.sourceforge.net/viewvc/obo/obo/ontology/phenotype/environment/environment_ontology.obo?view=co" -O environment_ontology.obo
wget "http://palea.cgrb.oregonstate.edu/viewsvn/Poc/trunk/ontology/collaborators_ontology/gramene/traits/trait.obo?view=co" -O trait.obo
wget "http://svn.code.sf.net/p/efo/code/trunk/src/efoinobo/efo.obo" -O efo.obo
#wget "http://sourceforge.net/p/pombase/code/HEAD/tree/phenotype_ontology/releases/latest/fypo-simple.obo?format=raw" -O fypo.obo
wget "http://sourceforge.net/p/pombase/code/HEAD/tree/phenotype_ontology/peco.obo?format=raw" -O peco.obo
wget "http://purl.obolibrary.org/obo/cl-basic.obo" -O cl-basic.obo
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/mini-ontologies/pombe_mini_PR.obo" -O pro.obo
wget "http://pato.googlecode.com/svn/trunk/quality.obo" -O pato.obo
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/mini-ontologies/chebi.obo" -O chebi.obo
wget "http://www.berkeleybop.org/ontologies/obo-all/OGMS/OGMS.obo" -O ogms.obo
wget "http://www.brenda-enzymes.info/ontology/tissue/tree/update/update_files/BrendaTissueOBO" -O bto.obo
wget "http://www.berkeleybop.org/ontologies/obo-all/bfo/bfo.obo" -O bfo.obo
wget "http://unit-ontology.googlecode.com/svn/trunk/unit.obo" -O uo.obo
wget "https://evidenceontology.googlecode.com/svn/trunk/eco.obo" -O eco.obo


# Create the database
mysql -u$DBHIVEUSER -p$DBHIVEPASS -h$DBHIVEHOST -P$DBHIVEPORT -e "DROP DATABASE IF EXISTS ${hive_dbname};"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "DROP DATABASE IF EXISTS ${DBNAME};"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "CREATE DATABASE ${DBNAME};"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME < $ENS_DIR/misc-scripts/ontology/sql/tables.sql

# Load the ontologies into the db
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file ogms.obo --ontology OGMS
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file pato.obo --ontology PATO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file go.obo --ontology GO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file so.obo --ontology SO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file po.obo --ontology PO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file GR_tax-ontology.obo --ontology GR_TAX
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file temporal_gramene.obo --ontology GRO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file environment_ontology.obo --ontology EO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file trait.obo --ontology TO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file chebi.obo --ontology CHEBI
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file PBO.obo --ontology PBO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file PBQ.obo --ontology PBQ
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file MOD.obo --ontology MOD
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file fypo.obo --ontology FYPO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file fypo_extension.obo --ontology FYPO_EXT
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file peco.obo --ontology PECO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file PHIbase_ontology_v04_1.obo --ontology PHI
#perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file phip.obo --ontology PHIP
#perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file phie.obo --ontology PHIE
#perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file phi.obo --ontology PHI
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file bto.obo --ontology BTO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file bfo.obo --ontology BFO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file uo.obo --ontology UO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file efo.obo --ontology EFO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file pro.obo --ontology PR
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file eco.obo --ontology ECO
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/load_OBO_file.pl --host $DBHOST --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --file cl-basic.obo --ontology CL

# Final Steps
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/compute_closure.pl --host $DBHOST  --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME --config $EG_DIR/ensembl-production/scripts/ontology/scripts/closure_config.ini
perl $EG_DIR/ensembl-production/scripts/ontology/scripts/add_subset_maps.pl --host $DBHOST  --port $DBPORT --dbuser $DBUSER --dbpass $DBPASS --name $DBNAME

#
# HealthChecks
#
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -e "select ontology.ontology_id, ontology.name, accession, term.name from ontology join term using (ontology_id) left join relation on (term_id=child_term_id) where term.is_root=1 order by ontology.ontology_id;"

