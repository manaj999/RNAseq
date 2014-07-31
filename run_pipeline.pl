#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# THIS SCRIPT CAN BE RUN WITH FOUR DIFFERENT COMPONENTS.
## Part 1 accepts a FastQ file of the RNAseq sample and then runs it through tophat and cufflinks.
## Part 2 collects all files processed through Part 1 and runs them through cuffmerge and cuffquant individually.
	### The separation of Part 1 and Part 2 is necessary because cuffmerge cannot assemble 
	### a merged transcriptome assembly until all samples have been processed through cufflinks.
	### The merged.gtf file is neeeded to run cuffquant and cuffnorm.
## Part 3 collects all files processed through Part 2 and runs them through cuffnorm together.
## The fourth component (CD) is optional. It collects all files processed through Part 2 and runs them through cuffdiff.
	### The separation of Part 2 and Parts 3 and CD is necessary because both cuffnorm and cuffdiff 
	### can only be run once all samples have been processed through cuffquant

# EXAMPLE COMMAND LINE CALLS:
## perl run_pipeline.pl -i /home/kanagarajm/HSB103.A1C.fq -o /mnt/speed/kanagarajM/pipeline/ -g u -p 1



# DECLARE COMPONENT SUBROUTINES
sub run_tophat();
sub run_cufflinks();
sub run_cuffmerge();
sub run_cuffquant();
sub run_cuffnorm();
sub run_cummeRbund();
sub run_cuffdiff();


# DECLARE GLOBAL VARIABLES
## $input stores the absolute path of the input file to be used.
	### Part 1: FastQ file of sample
	### Part 2: th-out directory of sample
## $output stores the absolute path of the directory where files are to be output
	### Part 1 and Part 2: same path for both parts
## $genomeType specifies which version of the genome sequence is to be used
	### Part 1 and Part 2: 'u' for UCSC, 'e' for Ensembl, 'n' for NCBI
## $part specifies which part of the script is to be run
	### 1 for part 1 | 2 for part 2
## $genome, $genes, $merged variables store the path of files for easier access later in the script
## $log represents the output log file, while $cm and $cd are flags for cuffmerge and cuffdiff, respectively
## $runID is a unique integer ID for organizing and specifying samples to be processed. 
	### Allows user to use same output directory for all jobs.

my ( $input, $output, $genomeType, $part, $genome, $genes, $merged, $log, $cm, $cd, $runID, $assembly, $index, $transcriptome, $merge );

# Set defaults
$genomeType = "u";
$part = 0;

GetOptions(	
	'o=s' => \$output,
	'i=s' => \$input,
	'g=s' => \$genomeType,
	'p=i' => \$part,
	'cm' => \$cm,
	'cd' => \$cd,
	'r=i' => \$runID,
	'm=s' => \$merge
) or die "Incorrect input and/or output path!\n";

# Set variable paths
if ($genomeType eq "u") {
	$assembly = "UCSC/hg19";
}
elsif ($genomeType eq "e") {
	$assembly = "Ensembl/GRCh37";
}
elsif ($genomeType eq "n") {
	$assembly = "NCBI/build37.2";
}
$genes = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Annotation/Genes/genes.gtf";
$genome = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Sequence/WholeGenomeFasta/genome.fa";
$index = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Index/known";
$transcriptome = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Sequence/Bowtie2Index/genome";

if ($genomeType ne "u" && $genomeType ne "e" && $genomeType ne "n" ){
	$genes = "$genomeType/Annotation/Genes/genes.gtf";
	$genome = "$genomeType/Sequence/WholeGenomeFasta/genome.fa";
	$index = "$genomeType/Index/known";
	$transcriptome = "$genomeType/Sequence/Bowtie2Index/genome";
}

# FORMAT INPUT/OUTPUT
## The following string modifications are meant to ensure that the component subroutines
	## can communicate with each other by avoiding potential syntax errors from the user
## Additionally, this script will create directories to organize the output from each
	## individual component if they have not already been created
my ( $th_output, $cl_output, $cm_output, $cq_output, $cn_output, $cd_output, $cb_output );

$th_output = $output."th-out/";
$cl_output = $output."cl-out/";
$cm_output = $output."cm-out/";
$cq_output = $output."cq-out/";
$cn_output = $output."cn-out/";
$cd_output = $output."cd-out/";
$cb_output = $output."cb-out/";

unless (-e $th_output) { unless (mkdir $th_output) { die "Unable to create $th_output\n"; } }
unless (-e $cl_output) { unless (mkdir $cl_output) { die "Unable to create $cl_output\n"; } }
unless (-e $cm_output) { unless (mkdir $cm_output) { die "Unable to create $cm_output\n"; } }
unless (-e $cq_output) { unless (mkdir $cq_output) { die "Unable to create $cq_output\n"; } }
unless (-e $cn_output) { unless (mkdir $cn_output) { die "Unable to create $cn_output\n"; } }
unless (-e $cd_output) { unless (mkdir $cd_output) { die "Unable to create $cd_output\n"; } }
unless (-e $cb_output) { unless (mkdir $cb_output) { die "Unable to create $cb_output\n"; } }

# DECLARE FILE VARIABLE
## The $file variable is used to specify the file that is to be run by 
	## each of the component subroutines
	### For part 1, input will be the FastQ file of the sample.
	### For part 2, input will be the sample's directory in th-out
	### For part 3 and cuffdiff, input will be the sample's directory in cl-out
my $file = $input;


# CREATE LOG FILE
$log = ">>" . $output . "log_$runID.txt";
open(LOG, $log) or die "Can't open log";
my @time=localtime(time);




# MAIN
if ($part == 1) {

	# RUN TOPHAT SUBROUTINE
	run_tophat();

	# RUN CUFFLINKS SUBROUTINE
	run_cufflinks();

} elsif ($part == 2) {
	
	# RUN CUFFMERGE SUBROUTINE
	## Run cuffmerge only once based on command in pipeline.pl
	if ($cm && $merge eq "y") { 
		
		run_cuffmerge();

	}
	else {

		# RUN CUFFQUANT SUBROUTINE
		run_cuffquant();
		
	}
	
} elsif ($part == 3){
	# RUN CUFFNORM SUBROUTINE
		
	run_cuffnorm();



	# run cummeRbund here
	run_cummeRbund();
}


# RUN CUFFDIFF SEPARATELY
if ($cd){
	# RUN CUFFDIFF SUBROUTINE
		
	run_cuffdiff();

}

close(LOG);




###### SUBROUTINES FOR EACH STEP IN THE PIPELINE ######
sub run_tophat() {
	# Example command for this subroutine
	## perl run_tophat.pl -i /mnt/state_lab/proc/brainSpanRNAseq_align/HSB*.fq -o /mnt/speed/kanagarajm

	# Editing file name to organize in appropriate output directory
	my $newFilename = $file;
	$newFilename =~ s#\.fq##;
	$newFilename =~ s#\.gz##;
	$newFilename =~ s#^.*/##;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Running TopHat on sample $newFilename\n";
	
	$newFilename = $th_output . "th-out_" . $newFilename . "_$runID";

	# Run tophat
	`tophat -r 50 -p 8 -o $newFilename --library-type fr-unstranded --solexa1.3-quals --transcriptome-index=$index $transcriptome $file`;
	
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," TopHat complete: $newFilename.\n";

	# Store output filename for easy access by next step in the pipeline
	$file = $newFilename;
}

sub run_cufflinks() {
	# Example command for this subroutine
	## perl run_cufflinks.pl -i /mnt/speed/kanagarajm/th-out/th-out_HSB* -o /mnt/speed/kanagarajm -g u

	my $newFilename = $file;
	$file = $file . "/accepted_hits.bam";
	$newFilename =~ s#^.*/##;
	$newFilename =~ s#th-out_##;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Running Cufflinks on sample $newFilename\n";
	
	$newFilename = $cl_output . "cl-out_" . $newFilename;

	# Run cufflinks
	`cufflinks -p 8 -o $newFilename --multi-read-correct --frag-bias-correct $genome --library-type fr-unstranded $file`;
	
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Cufflinks complete: $newFilename.\n";

	$file = $newFilename;
}

sub run_cuffmerge() {
	# Example command for this subroutine
	## perl run_cuffmerge.pl -o /mnt/speed/kanagarajm -g u

	# Create assemblies.txt file after running all relevant samples through cufflinks, and prior to running cuffmerge
	`ls $output/cl-out/cl-out_*_$runID/transcripts.gtf > $output/cm-out/assemblies.txt`;


	$file = "$output/cm-out/assemblies.txt";
	my $newFilename = $cm_output . "cm-out_$runID";

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Running Cuffmerge: $newFilename\n";

	# Run cuffmerge
	`cuffmerge -p 8 -o $newFilename -g $genes -s $genome $file`;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Cuffmerge complete: $newFilename\n";

	# Store merged.gtf file for later access
	$merged = $newFilename . "/merged.gtf";
}

sub run_cuffquant() {
	# Example command for this subroutine
	## perl run_cuffquant.pl -i /mnt/speed/kanagarajm/th-out/th-out_HSB* -o /mnt/speed/kanagarajm -g u
	if ( $merge eq "y" ) {
		$merged = $cm_output . "cm-out_$runID/merged.gtf";
	}
	elsif ( $merge eq "n" ){
		$merged = $genes;
	}	

	$file = $input . "/accepted_hits.bam";
	my $newFilename = $input;
	$newFilename =~ s#^.*/##;
	$newFilename =~ s#th-out_##;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Running Cuffquant on sample $newFilename\n";

	$newFilename = $cq_output . "cq-out_" . $newFilename;

	# Run cuffquant
	`cuffquant -o $newFilename -p 8 --multi-read-correct --library-type fr-unstranded --frag-bias-correct $genome $merged $file`;
	
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Cuffquant complete: $newFilename\n";

	$file = $newFilename;
}

sub run_cuffnorm() {
	# Access merged transcriptome for use in cuffnorm
	if ( $merge eq "y" ) {
		$merged = $cm_output . "cm-out_$runID/merged.gtf";
	}
	elsif ( $merge eq "n" ){
		$merged = $genes;
	}	

	# Concatenate all 'abundances.cxb' files and sample names to be used in a single cuffnorm call.
	my $abundances = '';
	my $labels = '';

	my @files = glob("$output/cq-out/cq-out_*_$runID");
	foreach my $in (@files) {

		$file = $in . "/abundances.cxb";

		my $label = $in;
		$label =~ s#^.*/##;
		$label =~ s#cq-out_##;
		#$label =~ s#\.fq.*##;
		$label =~ s#_.*##;
		
		# Concatenate labels and 'abundances.cxb' filenames
		$labels = $labels . "$label,";
		$abundances = $abundances . "$file ";
	}

	$labels =~ s/.$// if (substr($labels, -1, 1) eq ",");
	$abundances =~ s/.$//;
	my $newFilename = $cn_output . "cn-out_$runID";
	
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Running Cuffnorm: $newFilename\n";

	`cuffnorm -p 8 --output-format cuffdiff -o $newFilename -L $labels $merged $abundances`;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Cuffnorm complete: $newFilename\n";
	
}

sub run_cummeRbund(){

	# can make them pipe to new directory just for those runs if you really care to
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Generating cummeRbund summary graphs: $cb_output\n";

	`Rscript cummeRpipe.r $cn_outputcn-out_$runID/ $cb_output $runID`;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," CummeRbund summary graphs are ready: $cb_output\n";
}

sub run_cuffdiff(){
	# Access merged transcriptome for use in cuffnorm
	if ( $merge eq "y" ) {
		$merged = $cm_output . "cm-out_$runID/merged.gtf";
	}
	elsif ( $merge eq "n" ){
		$merged = $genes;
	}	

	# Concatenate all 'abundances.cxb' files and sample names to be used in a single cuffdiff call.
	my $abundances = '';
	my $labels = '';

	my @files = glob("$input/cq-out_*_$runID");
	foreach my $in (@files) {

		$file = $in . "/abundances.cxb";

		my $label = $in;
		$label =~ s#^.*/##;
		$label =~ s#cq-out_##;
		#$label =~ s#\.fq.*##;
		$label =~ s#_.*##;
		
		
		# Concatenate labels and 'abundances.cxb' filenames
		$labels = $labels . "$label,";
		$abundances = $abundances . "$file ";
	}

	$labels =~ s/.$// if (substr($labels, -1, 1) eq ",");
	$abundances =~ s/.$//;
	my $newFilename = $cd_output . "cd-out_$runID";
	
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Running Cuffdiff: $newFilename\n";

	`cuffdiff -p 8 -u -b $genome -o $newFilename -L $labels $merged $abundances`;

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Cuffdiff complete: $newFilename\n";
	
}











