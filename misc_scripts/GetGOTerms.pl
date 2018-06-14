use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
  -host => 'mysql.ebi.ac.uk',
  -port => 4157,
  -user => 'anonymous',
  -db_version => 68
);

my $species = 'solanum_lycopersicum';

my $gene_adaptor = $registry->get_adaptor($species, 'core', 'Gene');
my $GO_adaptor =  $registry->get_adaptor( 'Multi', 'Ontology',
'OntologyTerm' );

 #Show the number of genes
my $gene_list = $gene_adaptor->fetch_all();
print "We have ", scalar(@{$gene_list}), " genes  in ",$species,"\n";

foreach my $gene (@$gene_list){
      my @GO_list = @{ $gene->get_all_xrefs('GO%') };
      print "We have ", scalar(@GO_list), " references for",$gene->stable_id,":\n";
      foreach my $GO (@GO_list){
              my $term = $GO_adaptor->fetch_by_accession($GO->display_id);
              print $GO->display_id,"\n";
              print $term->accession,"\n";
              print $term->name(),"\n";
              print $term->ontology(),"\n";
              print $term->definition(),"\n";
      }
}
