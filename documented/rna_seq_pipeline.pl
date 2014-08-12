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
	'pairedEnd' => \$paired
) or die "Incorrect input and/or output path!\n";


## do argument checks here and include a help message (carry over stuff from old pipeline.pl)

my $arguments = "$input $output $genomeType $runID";
$arguments = $arguments . " --cd" if($cd);
$arguments = $arguments . " --nocuffmerge" if($overrideCM);
$arguments = $arguments . " --altAnnotation" if($altAnnotation);
$arguments = $arguments . " --nodiscovery" if($overrideDisc);
$arguments = $arguments . " --pairedEnd" if($paired);

`sh rna_seq_pipeline.sh $arguments`;

# args: 1 input, 2 output, 3 genometype, 4 runID, 5 cd, 6 nocuffmerge, 7 altAnnotation, 8 nodiscovery, 9 pairedEnd