#!/usr/bin/perl
use strict;
use warnings;


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