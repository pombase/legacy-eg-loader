#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Test that only the allowed files are present in the FTP directory."
echo "    Any extra files are listed below:"
cd ../../

perl misc_scripts/testFTP_AllowedFiles.pl -eg_release $EG_RELEASE -rootDir $FTP_DIR
