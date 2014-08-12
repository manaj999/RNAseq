#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# perl pipeline.pl -i <INPUT> -o <OUTPUT> -g <GENOME> -p <PART> -r <RUNID> <OPTIONS>

## THIS SCRIPT ORGANIZES THE TUXEDO PIPELINE TO EFFECTIVELY COORDINATE EACH OF ITS STEPS
	### (TopHat, Cufflinks, Cuffmerge, Cuffquant, Cuffnorm, Cuffdiff, CummeRbund).

## Example run:
	### perl pipeline.pl -i /home/kanagarajm/samples_fq/ -o /mnt/state_lab/share/Manoj/rna_seq_out/ -g u -p 1 -r 81214 --pairedEnd

## REQUIRED ARGUMENTS:
	### -i : input ... Directory containing all fastq files to be run through pipeline
	### -o : output ... Directory where all output files will be organized and saved
	### -g : genome build ... Genome build to be used. "u" for UCSC, "e" for Ensembl, "n" for NCBI, "g10" for Gencode v10, "g19" for Gencode v19, "m2" for Gencode m2. 
		#### If using --altAnnotation, then specify PATH of directory containing necessary files for building transcriptome
	### -p : part ... part of the pipeline to be completed. 
		#### 0 => Build transcriptome from specified annotation
		#### 1 => Tophat and Cufflinks (optional)
		#### 2 => Cuffmerge (optional) 
		#### 3 => Cuffquant
		#### 4 => Cuffnorm and CummeRbund
	### -r : runID ... unique runID used to identify and organize outputs from a given run

## OPTIONS:
	### --nocuffmerge: use to skip running cuffmerge
	### --altAnnotation: use a different genome assembly.
		#### Use the -g option to specify directory where "Sequence", "Annotation" and "Index" folders are located.
		#### Necessary files include an annotation .gtf file and a fasta file of the organism's genome
		#### It is also necessary to index these files for Bowtie2.
	### --nodiscovery: use to skip gene/transcript discovery and only quantify reference annotation
		#### This option will skip the Cufflinks and Cuffmerge steps.
	### --pairedEnd: use for paired-end sequencing reads
		#### Name your FASTQ files such that paired-ends are identifiable using _R1 and _R2 tags.
		#### Example: "HSB103.DFC_R1.fq" and "HSB103.DFC_R2.fq" are acceptable paired-end read names.
	### --cd: cuffdiff
		#### cuffdiff can only be executed using this script specifically, and is not compatible with the rna_seq_pipeline.pl wrapper script
		#### This was designed to ensure the user is aware of the need to use cuffdiff, which significantly affects the runtime.

my ( $input, $output, $genomeType, $part, $runID, $overrideCM, $altAnnotation, $overrideDisc, $paired, $cd, $t, $tc, $assembly, $index, $genes, $transcriptome, $log, $merge, $novel );

GetOptions(	
	'i=s' => \$input,
	'o=s' => \$output,
	'g=s' => \$genomeType,
	'p=i' => \$part,
	'r=i' => \$runID,
	'nocuffmerge' => \$overrideCM,
	'altAnnotation' => \$altAnnotation,
	'nodiscovery' => \$overrideDisc,
	'pairedEnd' => \$paired,
	'cd' => \$cd
) or die "Incorrect input and/or output path!\n";

# Verify that part number is an accepted input
die "Invalid part number\n" unless ($part =~ /^[01234]$/);

# Open log file for relevant output
$log = ">>" . $output . "log_$runID.txt";
open(LOG, $log) or die "Can't open log";
my @time=localtime(time);
my $arguments = "";
$arguments = $arguments . "--nocuffmerge " if($overrideCM);
$arguments = $arguments . "--altAnnotation " if($altAnnotation);
$arguments = $arguments . "--nodiscovery " if($overrideDisc);
$arguments = $arguments . "--pairedEnd " if($paired);
$arguments = $arguments . "--cd " if($cd);

print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Run: perl pipeline.pl -i $input -o $output -g $genomeType -r $runID $arguments\n";

# Overriding discovery also must override cuffmerge
if ($overrideDisc) { $novel = "n"; } else {	$novel = "y"; }
$overrideCM = 1 if ($overrideDisc);
if ($overrideCM) { $merge = "n"; } else { $merge = "y"; }



### MAIN ###
if ($part == 0) {

	### BUILD TRANSCRIPTOME ###
	print LOG "Beginning building step.\n";

	# Prepare file paths
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
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Beginning TopHat and Cufflinks steps.\n";

	# Glob all fq.gz files to be run in parallel and processed through the Sun Grid Engine (IHG-Cluster) 
	## using the qsub command to execute tophat and cufflinks

	my $suffix = "*fq.gz";
	my @size = glob("$input/$suffix");

	# The t and tc variables manage how many jobs are run in parallel at once
	## If $tc is capped at 75, for example, only 75 part 1 jobs can be run at a time
	## Thus if there are 150 samples to be processed, the second set of 75 jobs will be queued behind the first
	## The $tc value set here is arbitrary and can be adjusted depending on cluster policies
	$tc = scalar(@size);
	$tc = 75 if ($tc > 100);

	$t = "1-".$tc;
	print LOG "Submitting $tc jobs to server at a time.\n";
	if ($paired){
		`/opt/sge625/sge/bin/lx24-amd64/qsub -t $t -tc $tc -v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel -S /bin/sh submit-paired_1.sh`;
	}
	else {
		`/opt/sge625/sge/bin/lx24-amd64/qsub -t $t -tc $tc -v ARG1=$input,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel -S /bin/sh submit_1.sh`;
	}
	
}
elsif ($part == 2){
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Completed TopHat and Cufflinks steps.\n";
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Beginning Cuffmerge step.\n";
	
	unless($overrideCM) {
		# After all samples have been processed in part 1, merge their transcripts using Cuffmerge before proceeding to cuffquant step
		`perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID -m $merge --cm`;
	}

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Completed Cuffmerge step.\n";	
}
elsif ($part == 3){
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Beginning Cuffquant step.\n";
	
	# Glob all relevant tophat output directories and run in parallel through Sun Grid Engine using qsub command to execute cuffquant
	my $suffix = "th-out/th-out_*_$runID";
	my @size = glob("$output/$suffix");
	$tc = scalar(@size);
	$t = "1-".$tc;
	$tc = 75 if ($tc > 100);

	`/opt/sge625/sge/bin/lx24-amd64/qsub -t $t -tc $tc -v ARG1=$output,ARG2=$output,ARG3=$genomeType,ARG4=$part,ARG5=$runID,ARG6=$suffix,ARG7=$merge,ARG8=$novel -S /bin/sh submit_2.sh`;
}
elsif ($part == 4){
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Completed Cuffquant step.\n";
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Beginning Cuffnorm and CummeRbund steps.\n";
	
	# After all samples have been run through cuffquant in Step 3, submit cuffnorm job to Sun Grid Engine
	`perl run_pipeline.pl -i $input -o $output -g $genomeType -p $part -r $runID -m $merge -n $novel`;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Completed Cuffnorm and CummeRbund steps.\n";
}

# Should differential expression analysis be of interest, submit cuffdiff job to Sun Grid Engine after completing Step 3
# Input directory must be the folder containing the cq-out directories for samples of interest
# In most cases, the modified input will be: ORIG_INPUT_PATH/cq-out/
if ($cd){
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]","Beginning Cuffdiff step.\n";
	
	`/opt/sge625/sge/bin/lx24-amd64/qsub -pe parallel 8 -V -S /usr/bin/perl run_pipeline.pl -i $input -o $output -g $genomeType -r $runID -m $merge -n $novel --cd`;
}
close(LOG);


