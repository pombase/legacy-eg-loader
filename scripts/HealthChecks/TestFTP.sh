#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that the files on the FTP directory are ready and up to date"
cd ../../

perl misc_scripts/testFTP.pl -eg_release $EG_RELEASE -rootDir $FTP_DIR/pombe
