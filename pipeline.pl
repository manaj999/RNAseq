#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# perl pipeline.pl -i <INPUT> -o <OUTPUT> -g <GENOME> -p <PART> -r <RUNID> <OPTIONS>
## ARGUMENTS:
	### -i : input ... Directory containing all fastq files to be run through pipeline
	### -o : output ... Directory where all output files will be organized and saved
	### -g : genome build ... Genome build to be used. "u" for UCSC, "e" for Ensembl, "n" for NCBI, "g10" for Gencode v10, "g19" for Gencode v19, "m2" for Gencode m2. 
		#### If using --altAnnotation, then specify PATH of directory containing necessary files for building transcriptome
	### -p : part ... part of the pipeline to be completed. 1 => Tophat and Cufflinks, 2 => Cuffmerge and Cuffquant, 3 => Cuffnorm
	### -r : runID ... unique runID used to identify and organize outputs from a given run
	### --cd: cuffdiff (see below)
	### --nocuffmerge: use to skip running cuffmerge
	### --altAnnotation: use a different genome assembly. Specify directory where "Sequence" and "Annotation" folders are located in -g option.
	### --nodiscovery: use to skip gene/transcript discovery and only quantify reference annotation
	### --pairedEnd: use for paired-end sequencing reads

# Three commands for entire pipeline:
## Part 1:
	### perl pipeline.pl -i /home/kanagarajm/fq_batch/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 1 -r 72414
## Part 2:
	### perl pipeline.pl -i /home/kanagarajm/fq_batch/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 2 -r 72414
## Part 3: 
	### perl pipeline.pl -i /home/kanagarajm/fq_batch/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 3 -r 72414

## If you are interested in using cuffdiff for differential expression analysis, use this command after completing Part 2:
	### perl pipeline.pl -i /mnt/speed/kanagarajM/pipeline_batch/cq-out/ -o /mnt/speed/kanagarajM/pipeline_batch/ -g u --cd -r 72414


my ( $input, $output, $genomeType, $part, $cd, $runID, $t, $tc, $assembly, $index, $genes, $transcriptome, $log, $overrideCM, $merge, $altAnnotation, $overrideDisc, $novel, $paired );
$part = 0;

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
die "Invalid part number\n" unless ($part =~ /^[0123]$/);
unless ($altAnnotation){
	die "Invalid genome type\n" unless (($genomeType =~ /^[uen]$/i) or ($genomeType =~ /^g1[09]$/i) or ($genomeType =~ /^m2$/i));
}


$input =~ s/.$// if (substr($input, -1, 1) eq "/");
$output = $output . "/" if (substr($output, -1, 1) ne "/");
$genomeType =~ s/.$// if ($altAnnotation && (substr($genomeType, -1, 1) eq "/"));

$log = ">>" . $output . "log_$runID.txt";
open(LOG, $log) or die "Can't open log";
my @time=localtime(time);

if ($overrideDisc) { $novel = "n"; } else {	$novel = "y"; }
$overrideCM = 1 if ($overrideDisc);
if ($overrideCM) { $merge = "n"; } else { $merge = "y"; }

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

close(LOG);





### MAIN ###
if ($part == 1) {

	# Glob all fq.gz files to be run in parallel and processed through the Sun Grid Engine (IHG-Cluster) using the qsub command to execute tophat and cufflinks
	my $suffix = "*.fq.gz";
	my @size = glob("$input/$suffix");
	$tc = scalar(@size);
	$t = "1-".$tc;
	if ($tc > 100) { $tc = 75; }

	`qsub -t $t -tc $tc -v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel,ARG9=$paired submit_pipeline.sh`;
}
elsif ($part == 2){
	unless($overrideCM) {
		# After all samples have been processed in part 1, merge their transcripts using Cuffmerge before proceeding to cuffquant step
		`perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID -m $merge --cm`;
	}
	

	# Glob all relevant tophat output directories and run in parallel through Sun Grid Engine using qsub command to execute cuffquant
	my $suffix = "th-out/th-out_*_$runID";
	my @size = glob("$output/$suffix");
	$tc = scalar(@size);
	$t = "1-".$tc;
	if ($tc > 100) { $tc = 75; }

	`qsub -t $t -tc $tc -v ARG1=$output,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel,ARG9=$paired submit_pipeline.sh`;
}
elsif ($part == 3){

	# After all samples have been run through cuffquant in Step 2, submit cuffnorm job to Sun Grid Engine
	`qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID -m $merge -n $novel`;
}

# Should differential expression analysis be of interest, submit cuffdiff job to Sun Grid Engine after completing Step 2
# Specify input as a directory containing cq-out folders for samples of interest
if ($cd){
	`qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -r $runID -m $merge -n $novel --cd`;
}



