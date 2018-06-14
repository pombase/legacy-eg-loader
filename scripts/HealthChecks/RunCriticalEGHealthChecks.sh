#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

cd $EG_DIR/ensj-healthcheck

# JAVA_HOME                                                                                                                                                                                                                                 
if [ -z "$JAVA_HOME" ]; then                                                                                                                                                                                                                
    JAVA_HOME="/nfs/panda/ensemblgenomes/external/java"                                                                                                                                                                                     
    PATH="$JAVA_HOME/bin:$PATH"                                                                                                                                                                                                             
fi                                                                                                                                                                                                                                          
export JAVA_HOME   
# Ant                                                                                                                                                                                                                                       
if [ -z "$ANT_HOME" ]; then                                                                                                                                                                                                                 
        export ANT_HOME=/nfs/panda/ensemblgenomes/external/apache-ant                                                                                                                                                                       
        PATH=$ANT_HOME/bin:$PATH                                                                                                                                                                                                            
fi
export ANT_HOME
export PATH

# Required to run the translation HC
PERL5LIB=$EG_DIR/ensj-healthcheck/perl:$PERL5LIB

echo "
# location of databases to test
host=${DBHOST}
port=${DBPORT}
user=ensro
driver=org.gjt.mm.mysql.Driver
 
# location of the production database (if needed by the test)
host1=${DBPRODHOST}
port1=${DBPRODPORT}
user1=${DBPRODUSER}
# Master schema - see CompareSchema healthcheck
# This setting is ignored if CompareSchema is not run
master.schema=master_schema_${ENSEMBL_RELEASE}
master.variation_schema=master_schema_variation_${ENSEMBL_RELEASE}
master.funcgen_schema=master_schema_funcgen_${ENSEMBL_RELEASE}

# Connection details for the previous release
# These are used for ComparePrevious checks
secondary.host=${DBPOMBEHOST}
secondary.port=${DBPOMBEPORT}
secondary.user=ensro
secondary.driver=org.gjt.mm.mysql.Driver

# List of databases to check (spaces separated, NOT regexps)
test_databases=${DBCORENAME} ${DBVARNAME} 
" > ${DBHOST}.hc.properties

#./run-configurable-testrunner.sh -g EGCoreGeneModelCritical -T EGCompareCoreSchema ProteinTranslation -c ${DBHOST}.hc.properties -d ${DBCORENAME} -R Text
#./run-configurable-testrunner.sh -g EGCoreAnnotationCritical -T  -c ${DBHOST}.hc.properties -d ${DBCORENAME} -R Text
#./run-configurable-testrunner.sh -g EGCoreMetaCritical -T  -c ${DBHOST}.hc.properties -d ${DBCORENAME} -R Text
./run-configurable-testrunner.sh -g EGCoreIntegrity -T ProteinTranslation -c ${DBHOST}.hc.properties -d ${DBCORENAME} -R Text

#./run-configurable-testrunner.sh -g EGVariation -T EGCompareVariationSchema -c ${DBHOST}.hc.properties -d ${DBVARNAME} -R Text


