#!/usr/bin/perl
use strict;
use warnings;

# USAGE: Used to print out separated file headers when Gencode internal and external were compared

open(HEAD, "<header.txt") or die "failed, $!";
my @titles;
while(<HEAD>){
	@titles = split(/\t/,$_);
}
foreach(@titles){
	/FPKM$/ and print $_,"\n";
}
#print scalar(@titles),"\n";
close HEAD;
