#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# perl run_pipeline.pl -i <INPUT> -o <OUTPUT> -g <GENOME> -p <PART> -r <RUNID> -m <MERGE> -n <NOVEL> -e <PAIRED> <OPTIONS>

## THIS EXECUTES EACH COMPONENT OF THE TUXEDO PIPELINE FOR A SINGLE FASTQ FILE

## Example run:
	### perl pipeline.pl -i /home/kanagarajm/samples_fq/HSB103.DFC_R1.fq.gz -o /mnt/state_lab/share/Manoj/rna_seq_out/ -g u -p 1 -r 81214 -m y -n n -e /home/kanagarajm/samples_fq/HSB103.DFC_R2.fq.gz --cd

## REQUIRED ARGUMENTS:
	### -i : input ... Input directory varies depending upon step of pipeline
		#### For part 1, input will be the FastQ file of the sample
		#### For part 3, input will be the sample's directory in the th-out folder
		#### For cuffdiff, input will be the sample's directory in the cq-out folder
		#### For parts 2 and 4, $input does not matter
	### -o : output ... Directory where all output files will be organized and saved
		#### Remains constant for all components
	### -g : genome build ... Genome build to be used. "u" for UCSC, "e" for Ensembl, "n" for NCBI, "g10" for Gencode v10, "g19" for Gencode v19, "m2" for Gencode m2. 
		#### If alternative annotation is being used, then specify PATH of directory where "Sequence" and "Annotation" folders are located.
	### -p : part ... part of the pipeline to be completed. 
		#### 0 => Build transcriptome from specified annotation
		#### 1 => Tophat and Cufflinks (optional)
		#### 2 => Cuffmerge (optional) 
		#### 3 => Cuffquant
		#### 4 => Cuffnorm and CummeRbund
	### -r : runID ... unique runID used to identify and organize outputs from a given run

## OPTIONS:
	### -merge: "y" indicates that cuffmerge step will occur, whereas "n" indicates that cuffmerge will be skipped
	### -novel: "y" indicates that novel junctions will be found in TopHat, whereas "n" indicates that they will be skipped
		#### "n" also results in cufflinks and cuffmerge being skipped
	### -paired: Stores the file path to the paired FASTQ file for TopHat in Part 1 
	
	### --cm: cuffmerge; secondary check to confirm whether or not to run Cuffmerge. If its value is 0, then cuffmerge will be skipped
	### --cd: cuffdiff; If its value is 0, then cuffdiff will be skipped
		#### cuffdiff can only be executed using this script specifically, and is not compatible with the rna_seq_pipeline.pl wrapper script
		#### This was designed to ensure the user is aware of the need to use cuffdiff, which significantly affects the runtime.

# DECLARE COMPONENT SUBROUTINES
sub run_tophat();
sub run_cufflinks();
sub run_cuffmerge();
sub run_cuffquant();
sub run_cuffnorm();
sub run_cummeRbund();
sub run_cuffdiff();

my ( $input, $output, $genomeType, $part, $genome, $genes, $merged, $log, $cm, $cd, $runID, $assembly, $index, $transcriptome, $merge, $novel, $paired );

GetOptions(	
	'i=s' => \$input,
	'o=s' => \$output,
	'g=s' => \$genomeType,
	'p=i' => \$part,
	'r=i' => \$runID,
	'm=s' => \$merge,
	'n=s' => \$novel,
	'e=s' => \$paired,
	'cm' => \$cm,
	'cd' => \$cd
) or die "Incorrect input and/or output path!\n";

# Prepare variable file paths
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

if ($genomeType ne "u" && $genomeType ne "e" && $genomeType ne "n" && $genomeType ne "g10" && $genomeType ne "g19" && $genomeType ne "m2"){
	$genes = "$genomeType/Annotation/Genes/genes.gtf";
	$genome = "$genomeType/Sequence/WholeGenomeFasta/genome.fa";
	$index = "$genomeType/Index/known";
	$transcriptome = "$genomeType/Sequence/Bowtie2Index/genome";
}
else{
	$genes = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Annotation/Genes/genes.gtf";
	$genome = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Sequence/WholeGenomeFasta/genome.fa";
	$index = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Index/known";
	$transcriptome = "/mnt/state_lab/reference/transcriptomeData/Homo_sapiens/$assembly/Sequence/Bowtie2Index/genome";
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
my $file = $input;


# CREATE LOG FILE
$log = ">>" . $output . "log_$runID.txt";
open(LOG, $log) or die "Can't open log";
my @time=localtime(time);




# MAIN
if ($part == 1) {

	# RUN TOPHAT SUBROUTINE
	run_tophat();

	unless ($novel eq "n") {
		# RUN CUFFLINKS SUBROUTINE
		run_cufflinks();
	}


} elsif ($part == 2) {
	
	# RUN CUFFMERGE SUBROUTINE
	## Run cuffmerge only once based on command in pipeline.pl
	if ($cm && $merge eq "y") { 
		
		run_cuffmerge();

	}
	
} elsif ($part == 3) {

	# RUN CUFFQUANT SUBROUTINE
	run_cuffquant();

} elsif ($part == 4){
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

	# Editing file name to organize in appropriate output directory
	my $newFilename = $file;
	$newFilename =~ s#\.fq##;
	$newFilename =~ s#\.gz##;
	$newFilename =~ s#^.*/##;
	$newFilename =~ s#_R1## if ($paired);

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Running TopHat on sample $newFilename\n";
	
	$newFilename = $th_output . "th-out_" . $newFilename . "_$runID";

	# Run tophat

	if ($novel eq "y"){
		if ($paired) {
			`/mnt/state_lab/progs/tophat/bin/tophat -r 50 -p 8 -o $newFilename --library-type fr-unstranded --solexa1.3-quals --transcriptome-index=$index $transcriptome $file $paired`;
		}
		else {
			`/mnt/state_lab/progs/tophat/bin/tophat -r 50 -p 8 -o $newFilename --library-type fr-unstranded --solexa1.3-quals --transcriptome-index=$index $transcriptome $file`;
		}
		
	}
	elsif ($novel eq "n"){
		if ($paired) {
			`/mnt/state_lab/progs/tophat/bin/tophat -r 50 -p 8 -o $newFilename --library-type fr-unstranded --solexa1.3-quals --no-novel-juncs --transcriptome-index=$index $transcriptome $file $paired`;
		}
		else {
			`/mnt/state_lab/progs/tophat/bin/tophat -r 50 -p 8 -o $newFilename --library-type fr-unstranded --solexa1.3-quals --no-novel-juncs --transcriptome-index=$index $transcriptome $file`;
		}
		
	}
	
	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," TopHat complete: $newFilename.\n";

	# Store output filename for easy access by next step in the pipeline
	$file = $newFilename;
}

sub run_cufflinks() {

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

	@time=localtime(time);
	print LOG "[",(1900+$time[5]),"-$time[4]-$time[3] $time[2]:$time[1]:$time[0]","]"," Generating cummeRbund summary graphs: $cb_output\n";

	$cn_output =~ s/.$// if (substr($cn_output, -1, 1) eq "/");
	`Rscript cummeRpipe.r $cn_output/cn-out_$runID/ $cb_output $runID`;

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









