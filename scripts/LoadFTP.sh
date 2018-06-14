# Set the required variables.
MY_DIR=`dirname $0`
source $MY_DIR/SetEnv

cd /ebi/ftp/pub/databases/pombase
mv ChromosomeStatistics.json ChromosomeStatistics.json.$OLDCHADODATE
cp /homes/mcdowall/Documents/Git/PomLoader/data/FTP/ChromosomeStatistics.json .

cd /ebi/ftp/pub/databases/pombase/pombe/Chromosome_contigs
# Place a copy in the OLD directory as well
mkdir -p OLD/$CHADODATE
cp *.contig OLD/$CHADODATE/
wget "http://curation.pombase.org/releases/dumps/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/chromosome1.contig"
wget "http://curation.pombase.org/releases/dumps/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/chromosome2.contig"
wget "http://curation.pombase.org/releases/dumps/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/chromosome3.contig"
wget "http://curation.pombase.org/releases/dumps/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/mating_type_region.contig"
wget "http://curation.pombase.org/releases/dumps/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/pMIT.contig"
wget "http://curation.pombase.org/releases/dumps/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombe-embl/telomeric.contig"

cd /ebi/ftp/pub/databases/pombase/pombe/Chromosome_Dumps
mkdir -p OLD/$OLDCHADODATE
mv *.fa.gz OLD/$OLDCHADODATE/
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/current/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.20.dna.chromosome.I.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.21.dna.I.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/current/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.20.dna.chromosome.II.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.21.dna.II.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/current/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.20.dna.chromosome.III.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.21.dna.III.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/current/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.20.dna.chromosome.MT.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.21.dna.MT.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/current/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.20.dna.chromosome.MTR.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.21.dna.MTR.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/current/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.20.dna.chromosome.AB325691.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.21.dna.AB325691.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/current/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.20.dna.toplevel.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.20.dna.genome.fa.gz

mv *.embl OLD/$OLDCHADODATE/
mv *.genbank OLD/$OLDCHADODATE/
mv *.gff3 OLD/$OLDCHADODATE/
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/*.embl .
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/*.gff3 .
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/*.genbank .


cd /ebi/ftp/pub/databases/pombase/pombe/Mappings
mkdir -p OLD/$OLDCHADODATE
cp allNames.tsv OLD/$OLDCHADODATE/
cp sysID2product.tsv OLD/$OLDCHADODATE/
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/allNames.tsv .
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/sysID2product.tsv .

cd /ebi/ftp/pub/databases/pombase/pombe/CDS_Coordinates
mkdir -p OLD/$OLDCHADODATE
cp *.coords OLD/$OLDCHADODATE/
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/chromosome1.cds.coords .
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/chromosome2.cds.coords .
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/chromosome3.cds.coords .

cd /ebi/ftp/pub/databases/pombase/pombe/Exon_Coordinates
mkdir -p OLD/$OLDCHADODATE
mv *.coords OLD/$OLDCHADODATE/
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/chromosome1.exon.coords .
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/chromosome2.exon.coords .
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/chromosome3.exon.coords .

cd /ebi/ftp/pub/databases/pombase/FASTA
mkdir -p OLD/$OLDCHADODATE
mv *.gz OLD/$OLDCHADODATE/
cp /homes/mcdowall/Documents/Git/PomLoader/data/FTP/cdna_introns_utrs.fa.gz .
cp /homes/mcdowall/Documents/Git/PomLoader/data/FTP/cdna_nointrons_noutrs.fa.gz .
cp /homes/mcdowall/Documents/Git/PomLoader/data/FTP/cdna_nointrons_utrs.fa.gz .
cp /homes/mcdowall/Documents/Git/PomLoader/data/FTP/ncrna.fa.gz .
cp /homes/mcdowall/Documents/Git/PomLoader/data/FTP/pep.fa.gz .

cd /ebi/ftp/pub/databases/pombase/pombe/UTR
mkdir -p OLD/$OLDCHADODATE
mv *.gz OLD/$OLDCHADODATE/
cp /homes/mcdowall/Documents/Git/PomLoader/data/FTP/*UTR.fa.gz .

cd /ebi/ftp/pub/databases/pombase/pombe/Protein_data
mkdir -p OLD/$OLDCHADODATE
mv PeptideStates.tsv OLD/$OLDCHADODATE/
cp /nfs/panda/ensemblgenomes/development/mcdowall/Code/PomLoader_Pipelines/data/FTP/PeptideStates.tsv .

cd /ebi/ftp/pub/databases/pombase/pombe/Gene_ontology/
mkdir -p OLD/$OLDCHADODATE
mv gene_association.pombase.gz OLD/$OLDCHADODATE
wget "http://viewvc.geneontology.org/viewvc/GO-SVN/trunk/gene-associations/gene_association.pombase.gz" gene_association.pombase.gz

cd /ebi/ftp/pub/databases/pombase/pombe/orthologs/
mkdir -p OLD/$OLDCHADODATE
mv *-orthologs.txt OLD/$OLDCHADODATE/.
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombase-build-$PB_RELEASE-v1-l1.human-orthologs.txt" -O human-orthologs.txt
#wget "http://curation.pombase.org/dumps/pombase-chado-v$PB_VERSION-$PB_RELEASE/pombase-build-$PB_RELEASE-v1-l1.cerevisiae-orthologs.txt" -O cerevisiae-orthologs.txt
echo "pombase-chado-v$PB_VERSION-$PB_RELEASE" > README

