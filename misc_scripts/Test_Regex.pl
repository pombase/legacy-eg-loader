#!/usr/bin/env perl

use Data::Dumper;

#my $desc = 'GTP binding protein Sey1 (predicted) [Source:PomBase;Acc:SPAC222.14c] [Source:PomBase Gene ID;Acc:SPAC222.14c]';
#my $desc = 'GTP binding protein Sey1 (predicted) ';
my $desc = 'GTP binding protein [Source:PomBase;Acc:SPAC222.14c] [Source:PomBase Gene ID;Acc:SPAC222.14c] Sey1 (predicted)';

print Dumper $desc;

#my (@output) = ($desc =~ m/^[A-Za-z0-9 ]*[A-Za-z0-9]/g);
#my (@output) = ($desc =~ m/^[^\[]*(?= )/g);
$desc =~ s/\[.+\]$//;
$desc =~ s/\s$//;

#print Dumper $output;

print Dumper $desc;

print "|" . $desc . "|";