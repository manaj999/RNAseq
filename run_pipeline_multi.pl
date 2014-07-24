#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# See run_pipeline.pl for more detailed documentation

# example command to run this from cmdline, dont need to qsub, just run and specify part
## qlogin -l h=ihg-node-1
## perl run_pipeline_multi.pl -i /home/kanagarajm/fq/ -o /mnt/speed/kanagarajM/pipeline/ -g u -p 1 -r 72314
## perl run_pipeline_multi.pl -i /home/kanagarajm/fq/ -o /mnt/speed/kanagarajM/pipeline/ -g u -p 2 -r 72314
## perl run_pipeline_multi.pl -i /home/kanagarajm/fq/ -o /mnt/speed/kanagarajM/pipeline/ -g u -p 3 -r 72314
## perl run_pipeline_multi.pl -i /mnt/speed/kanagarajM/pipeline/cq-out/ -o /mnt/speed/kanagarajM/pipeline/ -g u -r 72314 --cd
	### by having a different input, cuffdiff allows for greater specificity as to which samples are to be used


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
	# Run all fq.gz files in directory "../fq/" through part 1 of run_pipeline.pl
	my @files = glob("$input/*.fq.gz");
	# count length of array
	foreach my $file (@files) {
		# make a log file, have run_pipeline.pl print out once each run is complete, dont move on to part 2 until the log has as many elements as the array
		`qsub -V -S /usr/bin/perl run_pipeline.pl -i $file -o $output -g $genomeType -p $part -r $runID`;
	}
}
elsif ($part == 2){
	# Run all th-out directories in "../th-out/" through part 2 of run_pipeline.pl

	# add condition to do cuffmerge just once, run perl script
	`/usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID --cm`;

	# cq
	my @files = glob("$output/th-out/th-out_*_$runID");
	foreach my $file (@files) {
		`qsub -V -S /usr/bin/perl run_pipeline.pl -i $file -o $output -g $genomeType -p $part -r $runID`;
	}
}
elsif ($part == 3){
	# cuffnorm has to have its own part because cannot run until all cxb files are ready
	# can you do the for loop in run_pipeline.pl? this will make it so you can still use qsub

	#qsub here a run_pipeline.pl call with appropriate parameters
		## what is input? output should be same
	`qsub -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID`;
}

# cuffdiff, to be run after all other processes
# user should input which directory is input, say it should be selected directory with the cq-out directories from the program
if ($cd){
	`qsub -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -r $runID --cd`;
}

