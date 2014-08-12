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

# String checks and manipulation
die "Invalid part number\n" unless ($part =~ /^[01234]$/);
unless ($altAnnotation){
	die "Invalid genome type\n" unless (($genomeType =~ /^[uen]$/i) or ($genomeType =~ /^g1[09]$/i) or ($genomeType =~ /^m2$/i));
} else {
	die "Invalid genome type\n" if (($genomeType =~ /^[uen]$/i) or ($genomeType =~ /^g1[09]$/i) or ($genomeType =~ /^m2$/i));
}


$input =~ s/.$// if (substr($input, -1, 1) eq "/");
$output = $output . "/" if (substr($output, -1, 1) ne "/");
$genomeType =~ s/.$// if ($altAnnotation && (substr($genomeType, -1, 1) eq "/"));

$log = ">>" . $output . "log_$runID.txt";


if ($overrideDisc) { $novel = "n"; } else {	$novel = "y"; }
$overrideCM = 1 if ($overrideDisc);
if ($overrideCM) { $merge = "n"; } else { $merge = "y"; }
open(LOG, $log) or die "Can't open log";

### MAIN ###

if ($part == 0) {

	
	my @time=localtime(time);

	### BUILD TRANSCRIPTOME ###
	if ($genomeType eq "u") {
		$assembly = "UCSC/hg19";
	}
	elsif ($genomeType eq "e") {
		$assembly = "Ensembl/GRCh37";
	}
	elsif ($genomeType eq "n") {
		$assembly = "NCBI/build37.2";
	}
	elsif ($genomeType eq "g10") {
		$assembly = "GENCODE/v10";
	}
	elsif ($genomeType eq "g19") {
		$assembly = "GENCODE/v19";
	}
	elsif ($genomeType eq "m2") {
		$assembly = "GENCODE/m2";
	}



	unless ($altAnnotation){
		$index = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Index/known";
	}
	else{
		$index = "$genomeType/Index/known";
	}


	unless (-e "$index.gff") {
		unless ($altAnnotation) {
			$genes = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Annotation/Genes/genes.gtf";
			$transcriptome = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Sequence/Bowtie2Index/genome";
		}
		else {
			$genes = "$genomeType/Annotation/Genes/genes.gtf";
			$transcriptome = "$genomeType/Sequence/Bowtie2Index/genome";
		}
		

		@time=localtime(time);
		print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Building transcriptome...\n";

		`tophat -p 8 -G $genes --transcriptome-index=$index $transcriptome`;

		@time=localtime(time);
		print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Finished building transcriptome.\n";
	}

	print LOG "Completed building step.\n";
	
}

if ($part == 1) {
	# Glob all fq.gz files to be run in parallel and processed through the Sun Grid Engine (IHG-Cluster) using the qsub command to execute tophat and cufflinks

	my $suffix = "*fq.gz";
	my @size = glob("$input/$suffix");
	$tc = scalar(@size);
	$t = "1-".$tc;
	$tc = 75 if ($tc > 100);

	
	if ($paired){
		`/opt/sge625/sge/bin/lx24-amd64/qsub -t $t -tc $tc -v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel -S /bin/sh submit-paired_1.sh`;
	}
	else {
		`/opt/sge625/sge/bin/lx24-amd64/qsub -t $t -tc $tc -v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel -S /bin/sh submit_1.sh`;
	}
	
}
elsif ($part == 2){
	unless($overrideCM) {
		# After all samples have been processed in part 1, merge their transcripts using Cuffmerge before proceeding to cuffquant step
		`perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID -m $merge --cm`;
	}	
}
elsif ($part == 3){
	# Glob all relevant tophat output directories and run in parallel through Sun Grid Engine using qsub command to execute cuffquant
	my $suffix = "th-out/th-out_*_$runID";
	my @size = glob("$output/$suffix");
	$tc = scalar(@size);
	$t = "1-".$tc;
	$tc = 75 if ($tc > 100);

	`/opt/sge625/sge/bin/lx24-amd64/qsub -t $t -tc $tc -v ARG1=$output,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel -S /bin/sh submit_2.sh`;
}
elsif ($part == 4){

	# After all samples have been run through cuffquant in Step 2, submit cuffnorm job to Sun Grid Engine
	`perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID -m $merge -n $novel`;
}

# Should differential expression analysis be of interest, submit cuffdiff job to Sun Grid Engine after completing Step 2
# Specify input as a directory containing cq-out folders for samples of interest
if ($cd){
	`/opt/sge625/sge/bin/lx24-amd64/qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -r $runID -m $merge -n $novel --cd`;
}
close(LOG);


