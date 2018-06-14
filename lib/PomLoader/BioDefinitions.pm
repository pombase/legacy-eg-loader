package PomLoader::BioDefinitions;

use Moose;

has 'dba_chado'    => ( isa => 'Bio::Chado::Schema', is => 'ro', required => 1 );

has 'go'           => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_godefs' );
has 'biotype'      => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_biotypes' );
has 'biotype_id'   => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_biotypes_id' );
has 'organism'     => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_organism' );
has 'organism_id'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_organism_id' );
has 'chado_type'   => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_chado_type' );
has 'ensembl_type' => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_ensembl_type' );
has 'db_translate' => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_db_names' );
has 'interaction_evid' => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_interaction_evidence' );

sub _generate_godefs {
    my %goevidence = (
        'inferred from experiment'                        => 'EXP',
        'inferred by curator'                             => 'IC',
        'inferred from biological aspect of ancestor'     => 'IBA',
        'inferred from biological aspect of descendant'   => 'IBD',
        'inferred from direct assay'                      => 'IDA',
        'inferred from electronic annotation'             => 'IEA',
        'inferred from expression pattern'                => 'IEP',
        'inferred from genomic context'                   => 'IGC',
        'inferred from genetic interaction'               => 'IGI',
        'inferred from key residues'                      => 'IKR',
        'inferred from mutant phenotype'                  => 'IMP',
        'inferred from physical interaction'              => 'IPI',
        'inferred from rapid divergence'                  => 'IRD',
        'inferred from sequence alignment'                => 'ISA',
        'inferred from sequence model'                    => 'ISM',
        'inferred from sequence orthology'                => 'ISO',
        'inferred from sequence or structural similarity' => 'ISS',
        'non-traceable author statement'                  => 'NAS',
        'no biological data available'                    => 'ND',
        'not recorded'                                    => 'NR',
        'inferred from reviewed computational analysis'   => 'RCA',
        'traceable author statement'                      => 'TAS',
    );
    return \%goevidence;
}

# select distinct feature.type_id, cvterm.name from feature, cvterm where feature.type_id=cvterm.cvterm_id and feature.organism_id=27;
sub _generate_biotypes {
#    my %biotypeid = (
#        '100' => 'scRNA',#uma 
#        '321' => 'protein_coding',
#        '362' => 'snoRNA',
#        '361' => 'snRNA',
#        '743' => 'ncRNA',
#        '339' => 'rRNA',
#        '340' => 'tRNA',
#        '423' => 'pseudogene',
#        '604' => 'pseudogenic_transcript'
#    );
#    return \%biotypeid
    my $self = shift;
    my $biotypes = $self->_get_biotypes_from_chado();
    return $biotypes->{'idtype'};
}

sub _generate_biotypes_id {
#    my %typeid = (
#        'scRNA'                    => 100,  #uma 
#        'chromosome'               => 427,
#        'contig'                   => 236,
#        'mitochondrial_chromosome' => 907,
#        'repeat_region'            => 745,
#        'gap'                      => 818,
#        'gene'                     => 792,
#        'mRNA'                     => 321,
#        'snRNA'                    => 361,
#        'snoRNA'                   => 362,
#        'ncRNA'                    => 743,
#        'rRNA'                     => 339,
#        'tRNA'                     => 340,
#        'polypeptide'              => 191,
#        'exon'                     => 234,
#        'region'                   => 87,
#        'seqRegion'                => 87,
#        'pseudogenic_transcript'   => 604,
#        'pseudogenic_exon'         => 595,
#        'pseudogene'               => 423,
#    );
#    return \%typeid;
    my $self = shift;
    my $biotypes = $self->_get_biotypes_from_chado();
    return $biotypes->{'typeid'};
}

sub _get_biotypes_from_chado {
    my $self = shift;
    
    my $rs = $self->dba_chado->resultset('Sequence::Feature')
        ->search(
            {},
            {select => ['me.type_id'],
             join => ['type'],
             '+select' => ['type.name',],
             '+as' => ['name'],
             'distinct' => 1
            }
        );
    
    my %typeid;
    my %idtype;
    while( my $rs_biotype = $rs->next) {
        #print $rs_biotype->type_id . "\t" . $rs_biotype->get_column('name') . "\n";
        $idtype{$rs_biotype->type_id} = $rs_biotype->get_column('name');
        $typeid{$rs_biotype->get_column('name')} = $rs_biotype->type_id; 
    }
    
    return {'typeid' => \%typeid, 'idtype' => \%idtype};
}

sub _generate_ensembl_type {
    my %biotypeid = (
        'mRNA'                   => 'protein_coding',
        'ncRNA'                  => 'ncRNA', #uma
        'scRNA'                  => 'scRNA', #uma  
        'snoRNA'                 => 'snoRNA',
        'snRNA'                  => 'snRNA',
        'ncRNA'                  => 'ncRNA',
        'rRNA'                   => 'rRNA',
        'tRNA'                   => 'tRNA',
        'pseudogene'             => 'pseudogene',
        'pseudogenic_transcript' => 'pseudogenic_transcript'
    );
    return \%biotypeid
}

sub _generate_chado_type {
    my %typeid = (
        'chromosome'               => 'chromosome',
        'mitochondrial_chromosome' => 'mitochondrial_chromosome',
        'repeat_region'            => 'repeat_region',
        'gap'                      => 'gap',
        'gene'                     => 'gene',
        'mRNA'                     => 'mRNA',
        'snRNA'                    => 'snRNA',
        'snoRNA'                   => 'snoRNA',
        'ncRNA'                    => 'ncRNA',
        'rRNA'                     => 'rRNA',
        'tRNA'                     => 'tRNA',
        'polypeptide'              => 'polypeptide',
        'exon'                     => 'exon',
        'region'                   => 'region',
        'seqRegion'                => 'seqRegion',
        'nuclear_mt_pseudogene'    => 'nuclear_mt_pseudogene',
        'pseudogenic_transcript'   => 'pseudogenic_transcript',
        'pseudogenic_exon'         => 'pseudogenic_exon',
        'pseudogene'               => 'pseudogene',
        'five_prime_UTR'           => 'five_prime_UTR',
        'three_prime_UTR'          => 'three_prime_UTR',
    );
    return \%typeid;
}


sub _generate_organism {
    my $self = shift;
    my $organisms = $self->_get_organisms_from_chado();
    return $organisms->{'idorganism'};
}

sub _generate_organism_id {
    my $self = shift;
    my $organisms = $self->_get_organisms_from_chado();
    return $organisms->{'organismid'};
}


sub _get_organisms_from_chado {
    my $self = shift;
    
    my $rs = $self->dba_chado->resultset('Organism::Organism')
        ->search(
            {},
            {select => ['me.organism_id', 'genus', 'species'],
             'distinct' => 1
            }
        );
    
    my %organismid;
    my %idorganism;
    while( my $rs_organism = $rs->next) {
        #print $rs_biotype->type_id . "\t" . $rs_biotype->get_column('name') . "\n";
        $idorganism{$rs_organism->organism_id} = $rs_organism->genus . "_" . $rs_organism->species;
        $organismid{$rs_organism->genus . "_" . $rs_organism->species} = $rs_organism->organism_id; 
    }
    
    return {'organismid' => \%organismid, 'idorganism' => \%idorganism};
}

# type_id |        name        | db_id |   name   
#---------+--------------------+-------+----------
#     191 | polypeptide        |    46 | PMID
#     191 | polypeptide        |    59 | UniProt
#     191 | polypeptide        |    83 | InterPro
#     191 | polypeptide        |    91 | Pfam
#     191 | polypeptide        |    93 | PDB
#     191 | polypeptide        |   101 | Prosite
#     191 | polypeptide        |   134 | CTP
#     191 | polypeptide        |   139 | GI
#     504 | polypeptide_domain |    83 | InterPro
sub _generate_db_names {
    my %biotypeid = (
        'UniProt'  => 'Uniprot/SWISSPROT',
        'uniprotkb'  => 'Uniprot/SWISSPROT',
        'UniProtKB'  => 'Uniprot/SWISSPROT',
        'UniProtKB-KW'  => 'UniProtKB-KW',
        'UniProtKB-SubCell' => 'SP_SL',
        #'CTP'      => 'CTP',      # Comparison Pathway TriTryp Database, currently 404
        'CTP'      => 'GeneDB',
        'EMBL'     => 'EMBL',
        'KEGG'     => 'KEGG',
        'PMID'     => 'PUBMED',
        'DOI'      => 'DOI',
        'PB_REF'   => 'PB_REF',
        'ArrayExpress' => 'ArrayExpress',
        'prosite'  => 'ProSite',
        'pdb'      => 'PDB',
        'InterPro' => 'Interpro',
        'interpro' => 'Interpro',
        'GI'       => 'GI',
        'Rfam'     => 'RFAM',
        'Pfam'     => 'PFAM',
        'pfam'     => 'PFAM',
        'SPD'      => 'SPD',
        'GEO'      => 'GEO',
        'GOC'      => 'GO_REF',
        'GO_REF'   => 'GO_REF',
        'GO'       => 'GO',
        'go'       => 'GO',
        'SO'       => 'SO',
        'SGD'      => 'SGD',
        'sgd'      => 'SGD',
        'genedb_spombe' => 'PomBase_GENE',
        'GeneDB_Spombe' => 'PomBase_GENE',
        'cbs'      => 'CBS',
        'tair'     => 'TAIR_LOCUS',
        'COG'      => 'COG',
        'cog'      => 'COG',
        'KOG'      => 'KOG',
        'kog'      => 'KOG',
        'mgi'      => 'MGI',
        'rgd'      => 'RGD',
        'fb'       => 'flybase_gene_id',
        'cgd'      => 'CGD',
        'WB'       => 'wormbase_gene',
        'wb'       => 'wormbase_gene',
        'smart'    => 'SMART',
        'dictybase' => 'dictyBase',
        'ecogene'  => 'EcoGene',
        'TAIR'     => 'TAIR_LOCUS',
        'tair'     => 'TAIR_LOCUS',
        'FB'       => 'flybase_gene_id',
        'fb'       => 'flybase_gene_id',
        'SP_KW'    => 'SP_KW',
        'SP_SL'    => 'SP_SL',
        'EC'       => 'EC_NUMBER',
        'AGI_LocusCode' => 'TAIR_LOCUS',
        'panther'  => 'PANTHER',
    );
    return \%biotypeid;
}

sub _generate_interaction_evidence {
  my %evid = (
    "Co-crystal Structure"          => "PBO:1710001",
    "Co-fractionation"              => "PBO:1710002",
    "Co-localization"               => "PBO:1710003",
    "Co-purification"               => "PBO:1710004",
    "Reconstituted Complex"         => "PBO:1710005",
    "Affinity Capture-Luminescence" => "PBO:1710006",
    "Affinity Capture-MS"           => "PBO:1710007",
    "Affinity Capture-RNA"          => "PBO:1710008",
    "Affinity Capture-Western"      => "PBO:1710009",
    "Biochemical Activity"          => "PBO:1710010",
    "Far Western"                   => "PBO:1710011",
    "FRET"                          => "PBO:1710012",
    "PCA"                           => "PBO:1710013",
    "Protein-peptide"               => "PBO:1710014",
    "Protein-RNA"                   => "PBO:1710015",
    "Two-hybrid"                    => "PBO:1710016",
    "Negative Genetic"              => "PBO:1710017",
    "Positive Genetic"              => "PBO:1710018",
    "Synthetic Growth Defect"       => "PBO:1710019",
    "Synthetic Haploinsufficiency"  => "PBO:1710020",
    "Synthetic Lethality"           => "PBO:1710021",
    "Synthetic Rescue"              => "PBO:1710022",
    "Dosage Growth Defect"          => "PBO:1710023",
    "Dosage Lethality"              => "PBO:1710024",
    "Dosage Rescue"                 => "PBO:1710025",
    "Phenotypic Enhancement"        => "PBO:1710026",
    "Phenotypic Suppression"        => "PBO:1710027",
    "Co-crystal or NMR structure"   => "PBO:1710028",
  );
  return \%evid;
}

1;

__END__

=head1 NAME

PomLoader::BioDefinitions - Converter of terms for the Chado database.

=head1 DESCRIPTION

This module provides mappings between the biological descriptions and ids in 
one place so that all modules can reference this point to  get a consistent set 
of mapping ids within the Chado database.

There are also term conversions such as the go Method for converting from the
Chado representation into a representation required by EnsEMBL.   If this 
module becomes overloaded with mixtures of the two then it could be split out
over two modules for each function.

=head2 Methods

=over 12

=item C<new>

Returns a PomBaseLoader::BioDefinitions object.

=item C<biotype_id>

Returns the id of a given biotype

=item C<biotype>

Returns the biotype of a given id

=item C<go>

Returns the short GO term evidence code for a given descriptive term.

=back

=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
Moose

=item
EnsEMBL API Release v61

=back

=head1 EXAMPLE

my $biodef = PomLoader::BioDefinitions->new();
$biodef->biotype_id()->{'gene'}
$biodef->biotype()->{'321'}
$biodef->go()->{'Inferred from Direct Assay'}

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut
