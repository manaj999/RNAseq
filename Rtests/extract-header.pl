#!/usr/bin/perl
use strict;
use warnings;


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
