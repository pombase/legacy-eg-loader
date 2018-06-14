#!/usr/bin/env python

#get library modules
import sys, os, argparse

parser = argparse.ArgumentParser(description='Generate an SQL file to update the ontology terms in the core database based on the matching terms in the ontology database.')
parser.add_argument('--host', help="Database host (eg mysql-devel-3)", default="mysql-eg-devel-3.ebi.ac.uk")
parser.add_argument('--port', help="Database host (eg mysql-devel-3)", default="4208")
parser.add_argument('--user', help="Database host (eg mysql-devel-3)", default="ensro")
parser.add_argument('--pswd', help="Database host (eg mysql-devel-3)", default="xxx")
parser.add_argument('--mart', help="Mart db name (eg fungi_mart_18)", default="fungi_mart_18")
args = parser.parse_args()

host = args.host # 'mysql-devel-3.ebi.ac.uk'
port = args.port # '4208'
user = args.user # 'ensro'
pwd  = args.pswd # 'xxx'
mart = args.mart   # 'fungi_mart_18'

#simple command line processing to get files (if, list)
folders=[ name for name in os.listdir('.') if os.path.isdir(os.path.join('.', name)) ]
filepwd = ''

fo = open('SQL_loader.sql', 'w')
for folder in folders:
    #print "Enter Loop:"
    print folder
    subfolder = folder.split('/')
    subfilepwd = filepwd + subfolder[-1]
    #print subfilepwd
    subfolders=[ name for name in os.listdir(subfilepwd) if os.path.isdir(os.path.join(subfilepwd, name)) ]
    if len(subfolders) > 0:
        subfilepwd += "/"+subfolders[0]
    #subfolders = folder.split('/')
    #print subfilepwd
    fi = open(subfilepwd+"/MANIFEST.txt", 'r')
    for line in fi:
        fo.write('echo "Loading ' + folder + ' ..."' + "\n")
        fo.write("mysql -u" + user + " -p" + pwd + " -h" + host + " -P" + port + " " + mart + " < " + subfilepwd + "/" + line)
    fi.close()

fo.close()

