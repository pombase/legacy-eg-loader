#!/usr/bin/env perl

use strict;
use warnings;
#use Readonly;
use Carp;
use diagnostics;
use DBI;
#use IO::File;
#use Time::Local;
use Getopt::Long;
use POSIX;
use Digest::MD5;
use Data::Dumper;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $oracle_sid  = 'UAPRO';
my $oracle_host = 'ora-vm-004.ebi.ac.uk';
my $oracle_port = '1551';
my $oracle_user = 'yyy';
my $oracle_pwd  = 'xxx';
my $ensembl_host = 'mysql-eg-devel-3.ebi.ac.uk';
my $ensembl_port = '4208';
my $ensembl_user = 'xxx';
my $ensembl_pwd  = 'yyy';
my $division = 'EnsemblFungi';
my $species = 'schizosaccharomyces_pombe';
my $dbname  = 'schizosaccharomyces_pombe_core_21_74_2';

sub usage {
    print "Usage: $0 [-osid <SID>]\n";
    print "-osid  <SID>  Default is $oracle_sid\n";
    print "-ohost <Host> Default is $oracle_host\n";
    print "-oport <Port> Default is $oracle_port\n";
    print "-ouser <User> Default is $oracle_user\n";
    print "-opass <pass> Default is $oracle_pwd\n";
    print "-ehost <Host> Default is $ensembl_host\n";
    print "-eport <Port> Default is $ensembl_port\n";
    print "-euser <User> Default is $ensembl_user\n";
    print "-epass <pass> Default is $ensembl_pwd\n";
    print "-division <Division> Default is $division\n";
    print "-species <species> Default is $species\n";
    print "-dbname  <db> Default is $dbname\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("osid=s"  => \$oracle_sid,
                               "ohost=s" => \$oracle_host,
                               "oport=i" => \$oracle_port,
                               "ouser=s" => \$oracle_user,
                               "opass=s" => \$oracle_pwd,
                               "ehost=s" => \$ensembl_host,
                               "eport=i" => \$ensembl_port,
                               "euser=s" => \$ensembl_user,
                               "epass=s" => \$ensembl_pwd,
                               "division=s" => \$division,
                               "species=s" => \$species,
                               "dbname=s"  => \$dbname,
                               "help"    => sub {usage()});

if(!$options_okay) {
    usage();
}

my $db = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
  '-host'    => $ensembl_host,
  '-port'    => $ensembl_port,
  '-user'    => $ensembl_user,
  '-group'   => 'core',
  '-species' => $species,
  '-dbname'  => $dbname,
  '-pass'    => $ensembl_pwd
);

my $dbh0 = DBI->connect("dbi:Oracle:host=$oracle_host;port=$oracle_port;sid=$oracle_sid", $oracle_user, $oracle_pwd)
                or die "Unable to initialize DB connection : " . DBI->errstr;
my $sql_query="select p.upi, x.ac, d.display_name from uniparc.protein p join uniparc.xref x on (x.upi=p.upi) join uniparc.cv_database d on (x.dbid=d.id) where uniprot='Y' and md5=?";
my $sth0 = $dbh0->prepare("$sql_query") or die "Could not query Oracle Database " . $dbh0->errstr;


my $dsn = sprintf( "DBI:mysql:host=%s;port=%d", $ensembl_host, $ensembl_port );
my $dbh = DBI->connect( $dsn, $ensembl_user, $ensembl_pwd,
                        { 'RaiseError' => 0, 'PrintError' => 0 } );

my $sth = $dbh->prepare("SHOW DATABASES LIKE ?");
$sth->bind_param( 1, $dbname );

$sth->execute();
print "$ensembl_host\t$ensembl_port\t$ensembl_user\t$ensembl_pwd\t$division\n";

my $database;
$sth->bind_col( 1, \$database );

DATABASE:
while ( $sth->fetch() ) {
  print "$database\n";
  if ( $database =~ /^(?:information_schema|mysql)$/ ) { next }
  
  # Figure out schema version, schema type, and species name from the
  # database by querying its meta table.

#  my $sth2 = $dbh->prepare(
#               "SELECT meta_key, meta_value FROM ? WHERE meta_key='species.division';",
#             );
#  $sth2->bind_param( 1, $database );
  
  print sprintf("SELECT meta_key, meta_value FROM %s WHERE meta_key='species.division';",$dbh->quote_identifier( undef, $database, 'meta' ) ) . "\n";
  
  my $sth2 = $dbh->prepare(
            sprintf(
              "SELECT meta_key, meta_value FROM %s WHERE meta_key='species.division';",
              $dbh->quote_identifier( undef, $database, 'meta' ) ) );

  $sth2->execute();
  #print Dumper $sth2->fetch();

  my @rowdb = $sth2->fetch();
  print Dumper @rowdb;
  
  my ( $key, $value );
  
  #$sth2->bind_col( 1, \( $key, $value ) );
  $key = $rowdb[0][0];
  $value = $rowdb[0][1];
  
  print "$key\t$value\n"; 
  
  if ( $key eq 'species.division' and $value eq $division ) {

    #
    # Create a hash of all Chromosome slices
    #
    my $gene_adaptor = $db->get_adaptor('Gene');
    my @genes = @{ $gene_adaptor->fetch_all_by_biotype('protein_coding'); };
    
    print "Total number of protein_coding genes: " . scalar(@genes) . "\n";
    my $gene_count=0;
    
    foreach my $gene ( @genes ) {
      $gene_count++;
      
      #
      # Obtain all transcripts for a given gene and update annotations.
      #
      my @transcripts = @{ $gene->get_all_Transcripts };
      foreach my $transcript ( @transcripts ) {
        my $pep = $transcript->translate();
        my $translation = $transcript->translation();
        my $md5 = Digest::MD5->new;
        $md5->add(uc($pep->seq()));
        my $digest = uc($md5->hexdigest());
          
        #print "$digest\n";
        $sth0->execute($digest) or die "Could not execute query on Oracle Database" . $sth0->errstr;

        my @row = @{ $sth0->fetchall_arrayref };
        if (scalar( @row ) == 0) {
          print $gene->stable_id . " |";# $translation->dbID |";  
          #print Dumper $dbentry;
          print " " . $row[0][0] . ' | ' . $row[0][1] . "\n";
          print $translation->seq();
          print "\n";
          next;
        }
        
        #
        # Create a DBEntry for the feature_id
        #
        my $uniparc_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $row[0][0],
            -DBNAME      => 'UniParc',
            -DISPLAY_ID  => $row[0][0],
            -INFO_TYPE   => 'CHECKSUM',
        );
        
    #    my $uniprot_dbentry = Bio::EnsEMBL::DBEntry -> new (
    #        -PRIMARY_ID  => $row[0][1],
    #        -DBNAME      => 'UniProt/SWISSPROT',
    #        -DISPLAY_ID  => $row[0][1],
    #        -INFO_TYPE   => 'CHECKSUM',
    #    );
        
        
        
        
       $db->get_DBEntryAdaptor->store(
               $uniparc_dbentry,
               $translation->dbID,
               'Translation'
       );
        
        #$db->get_DBEntryAdaptor->store(
        #        $uniprot_dbentry,
        #        $translation->dbID,
        #        'Translation'
        #);
      }
      if ( $gene_count % 1000 == 0 ) {
        print "$gene_count Loaded\n";
      }
    }
  }
}    

$dbh->disconnect;
$dbh0->disconnect;
