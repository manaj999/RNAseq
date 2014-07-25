#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# See run_pipeline.pl for more detailed documentation



my ( $input, $output, $genomeType, $part, $cd, $runID );
$part = 0;

GetOptions(	
	'o=s' => \$output,
	'i=s' => \$input,
	'g=s' => \$genomeType,
	'p=i' => \$part,
	'cd' => \$cd,
	'r=i' => \$runID
) or die "Incorrect input and/or output path!\n";

#checks on input here before qsubbing
die "Invalid part number\n" unless ($part =~ /^[0123]$/);
die "Invalid genome type\n" unless ($genomeType =~ /^[uen]$/);

$input =~ s/.$// if (substr($input, -1, 1) eq "/");
$output = $output . "/" if (substr($output, -1, 1) ne "/"); 

#overwrite log file out here


### MAIN ###
if ($part == 1) {
	`qsub submit_pipeline_1.sh`;
}
elsif ($part == 2){
	`perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID --cm`;

	`qsub submit_pipeline_2.sh`;
}
elsif ($part == 3){
	`qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID`;
}

# cuffdiff, to be run after all other processes
# user should input which directory is input, say it should be selected directory with the cq-out directories from the program
if ($cd){
	`qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -r $runID --cd`;
}



