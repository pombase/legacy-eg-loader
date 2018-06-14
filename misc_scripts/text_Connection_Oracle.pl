#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use DBI;
use Data::Dumper;

my $oracle_sid  = 'UAPRO';
my $oracle_host = 'ora-vm-004.ebi.ac.uk';
my $oracle_port = '1551';
my $oracle_user = 'proteomes_prod';
my $oracle_pwd  = 'pprod';

my $dbh = DBI->connect("dbi:Oracle:host=$oracle_host;port=$oracle_port;sid=$oracle_sid", $oracle_user, $oracle_pwd)
                or die "Unable to initialize DB connection : " . DBI->errstr;

my $sql_query="select p.upi, x.ac, d.display_name from uniparc.protein p join uniparc.xref x on (x.upi=p.upi) join uniparc.cv_database d on (x.dbid=d.id) where uniprot='Y' and md5=?";

my $sth = $dbh->prepare("$sql_query") or die "Could not query Oracle Database " . $dbh->errstr;

# Upper case protien pom1
$sth->execute('5D2C6EF17B86DAE40486FCAA570B0922') or die "Could not execute query on Oracle Database" . $sth->errstr;

my @row = @{ $sth->fetchall_arrayref };
print "| $row[0][0] | $row[0][1] | $row[0][2] |\n";

#print "INSERT INTO xref (external_db_id, dbprimary_acc, display_label, info_type) SELECT external_db.external_db_id, $row[0][0], $row[0][0], 'CHECKSUM' FROM external_db WHERE external_db.db_name='$row[0][2]';\n";
#print "INSERT INTO object_xref ()";





my $oracle2_sid  = 'SWPREAD';
my $oracle2_host = 'whisky.ebi.ac.uk';
my $oracle2_port = '1531';
my $oracle2_user = 'proteomes_prod';
my $oracle2_pwd  = 'pprod';
my $dbh2 = DBI->connect("dbi:Oracle:host=$oracle2_host;port=$oracle2_port;sid=$oracle2_sid", $oracle2_user, $oracle2_pwd)
                or die "Unable to initialize DB connection : " . DBI->errstr;

$sql_query="select d.accession, d.name,dd.dbentry_id, dd.primary_id, dd.secondary_id from v_dbentry d join v_dbentry_2_dbs dd on (dd.dbentry_id=d.dbentry_id) where accession='Q09690';";

my $sth2 = $dbh2->prepare("$sql_query") or die "Could not query Oracle Database " . $dbh2->errstr;

$sth2->execute() or die "Could not execute query on Oracle Database" . $sth2->errstr;

@row = @{ $sth2->fetchall_arrayref };

print Dumper @row;


