#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# See run_pipeline.pl for more detailed documentation

## Three commands for entire pipeline:
# perl pipeline.pl -i /home/kanagarajm/fq_batch/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 1 -r 72414
# perl pipeline.pl -i /home/kanagarajm/fq_batch/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 2 -r 72414
# perl pipeline.pl -i /home/kanagarajm/fq_batch/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 3 -r 72414
# perl pipeline.pl -i /mnt/speed/kanagarajM/pipeline_batch/cq-out/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u --cd -r 72414
	### by having a different input, cuffdiff allows for greater specificity as to which samples are to be used


my ( $input, $output, $genomeType, $part, $cd, $runID, $t, $tc );
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

# prep t flag here


### MAIN ###
if ($part == 1) {
	my $suffix = "*.fq.gz";
	my @size = glob("$input/$suffix");
	$tc = scalar(@size);
	$t = "1-".$tc;
	if ($tc > 100) { $tc = 75; }

	`qsub -t $t -tc $tc -v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix submit_pipeline.sh`;
}
elsif ($part == 2){
	`perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID --cm`;

	my $suffix = "th-out/th-out_*_$runID";
	my @size = glob("$output/$suffix");
	$tc = scalar(@size);
	$t = "1-".$tc;
	if ($tc > 100) { $tc = 75; }

	`qsub -t $t -tc $tc -v ARG1=$output,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix submit_pipeline.sh`;
}
elsif ($part == 3){
	`qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID`;
}

# cuffdiff, to be run after all other processes
# user should input which directory is input, say it should be selected directory with the cq-out directories from the program
if ($cd){
	`qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -r $runID --cd`;
}



