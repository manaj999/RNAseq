#!/usr/bin/perl
use strict;
use warnings;

# USAGE: Used to remove gencode gene identifier suffixes so gencode processed from Nenad's lab could be compared 
## with gencode results processed from our lab

open(HEAD, "<gencode_IDs.txt") or die "failed, $!";
open(OUT, ">gencode_IDs_fixed.txt") or die "failed, $!";
my @titles;
while(<HEAD>){
	@titles = split(/\s/,$_);
}
foreach(@titles){

	#s#^.*/##;
	s/[.].*$// and print OUT $_,"\n";
	#/FPKM$/ and print $_,"\n";
}
#print scalar(@titles),"\n";
close HEAD;
close OUT;
