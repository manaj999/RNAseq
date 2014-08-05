#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my ( $input, $output, $genomeType, $part, $cd, $runID, $t, $tc, $assembly, $index, $genes, $transcriptome, $log, $overrideCM, $merge, $altAnnotation, $overrideDisc, $novel, $paired );

GetOptions(	
	'o=s' => \$output,
	'i=s' => \$input,
	'g=s' => \$genomeType,
	'p=i' => \$part,
	'cd' => \$cd,
	'r=i' => \$runID,
	'nocuffmerge' => \$overrideCM,
	'altAnnotation' => \$altAnnotation,
	'nodiscovery' => \$overrideDisc,
	'pairedEnd' => \$paired
) or die "Incorrect input and/or output path!\n";

my $arguments = "ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=runID";
$arguments = $arguments . ",ARG5=--cd" if($cd);
$arguments = $arguments . ",ARG6=--nocuffmerge" if($overrideCM);
$arguments = $arguments . ",ARG7=--altAnnotation" if($altAnnotation);
$arguments = $arguments . ",ARG8=--nodiscovery" if($overrideDisc);
$arguments = $arguments . ",ARG9=--pairedEnd" if($paired);

`qsub -V -l h=ihg-node-27 -v $arguments joined_pipeline.sh`;

#-v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel submit_pipeline_paired_1.sh

# args: 1 input, 2 output, 3 genometype, 4 runID, 5 cd, 6 nocuffmerge, 7 altAnnotation, 8 nodiscovery, 9 pairedEnd