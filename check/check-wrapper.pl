#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my ( $input, $output, $genomeType, $cd, $runID, $index, $overrideCM, $altAnnotation, $overrideDisc, $paired );

GetOptions(	
	'o=s' => \$output,
	'i=s' => \$input,
	'g=s' => \$genomeType,
	'cd' => \$cd,
	'r=i' => \$runID,
	'nocuffmerge' => \$overrideCM,
	'altAnnotation' => \$altAnnotation,
	'nodiscovery' => \$overrideDisc,
	'pairedEnd' => \$paired,
	'cd' => \$cd
) or die "Incorrect input and/or output path!\n";

# my $arguments = "ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$runID";
# $arguments = $arguments . ",ARG5=--cd" if($cd);
# $arguments = $arguments . ",ARG6=--nocuffmerge" if($overrideCM);
# $arguments = $arguments . ",ARG7=--altAnnotation" if($altAnnotation);
# $arguments = $arguments . ",ARG8=--nodiscovery" if($overrideDisc);
# $arguments = $arguments . ",ARG9=--pairedEnd" if($paired);

my $arguments = "$input $output $genomeType $runID";
$arguments = $arguments . " --cd" if($cd);
$arguments = $arguments . " --nocuffmerge" if($overrideCM);
$arguments = $arguments . " --altAnnotation" if($altAnnotation);
$arguments = $arguments . " --nodiscovery" if($overrideDisc);
$arguments = $arguments . " --pairedEnd" if($paired);

print $arguments."\n";
#`qsub -V -l h=ihg-node-27 -v $arguments test-wrapper.sh`;
`sh check-wrapper.sh $arguments`;

#-v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel submit_pipeline_paired_1.sh

# args: 1 input, 2 output, 3 genometype, 4 runID, 5 cd, 6 nocuffmerge, 7 altAnnotation, 8 nodiscovery, 9 pairedEnd