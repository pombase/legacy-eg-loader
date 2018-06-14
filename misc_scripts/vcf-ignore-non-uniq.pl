#!/usr/bin/perl
#ignores (doesn't print) any vcf lines that have been seen before
#by seen before I mean same chr,pos, and ref & alt lines
use strict;
use warnings;


#records all sites seen
my $seen = {};
my $number_removed=0;
my $removedfile = "vcf-ignore-non-uniq.$$.removed.lines.vcf";
open(DUP, ">$removedfile");

  
#parse line
while (<STDIN>){
	if ($_=~/#/){
		print $_;
		print DUP $_;
		next;
	};
	
	my ($CHROM,$POS,$ID,$REF,$ALT) = split("\t",$_);
	if (defined $seen->{$CHROM}{$POS}{$REF}{$ALT}){
		print DUP $_;	
		$number_removed++;
	}
	else {
		print $_;
		$seen->{$CHROM}{$POS}{$REF}{$ALT} =1;
	}
}

close DUP;
warn "\nDone. Removed $number_removed duplicated lines. File $removedfile contains the lines that were removed (and headers)\n\n";

