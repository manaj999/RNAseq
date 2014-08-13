#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# perl rna_seq_pipeline.pl -i <INPUT> -o <OUTPUT> -g <GENOME> -r <RUNID> <OPTIONS>

## This script serves as the wrapper for the entire Tuxedo pipeline.
## It has been written to optimize the processing of multiple FASTQ files produced via RNA sequencing
	### by running them modularly in parallel using the Oracle Sun Grid Engine (SGE).
## Together this collection of scripts can produce detailed expression metrics and publication-ready graphs
	### with just a single line of code from the command line.

## Example run:
	### perl rna_seq_pipeline.pl -i /home/kanagarajm/samples_fq/ -o /mnt/state_lab/share/Manoj/rna_seq_out/ -g u -r 81214 --pairedEnd

## REQUIRED ARGUMENTS:
	### -i : input ... Directory containing all fastq files to be run through pipeline
	### -o : output ... Directory where all output files will be organized and saved
	### -g : genome build ... Genome build to be used. "u" for UCSC, "e" for Ensembl, "n" for NCBI, "g10" for Gencode v10, "g19" for Gencode v19, "m2" for Gencode m2. 
		#### If using --altAnnotation, then specify PATH of directory containing necessary files for building transcriptome
	### -r : runID ... unique runID used to identify and organize outputs from a given run

## OPTIONS:
	### --nocuffmerge: use to skip running cuffmerge
	### --altAnnotation: use a different genome assembly. Specify directory where "Sequence" and "Annotation" folders are located in -g option.
	### --nodiscovery: use to skip gene/transcript discovery and only quantify reference annotation
	### --pairedEnd: use for paired-end sequencing reads


my ( $input, $output, $genomeType, $runID, $overrideCM, $altAnnotation, $overrideDisc, $paired, $help );

GetOptions(	
	'i=s' => \$input,
	'o=s' => \$output,
	'g=s' => \$genomeType,
	'r=i' => \$runID,
	'nocuffmerge' => \$overrideCM,
	'altAnnotation' => \$altAnnotation,
	'nodiscovery' => \$overrideDisc,
	'pairedEnd' => \$paired,
	'help' => \$help,
	'h' => \$help
) or die "Incorrect input and/or output path!\n";

if (!$input or !$output or !$genomeType or !$runID or $help){
	`clear`;
	print <<HelpDocumentation;
USAGE:
	perl rna_seq_pipeline.pl -i <INPUT> -o <OUTPUT> -g <GENOME> -r <RUNID> <OPTIONS>

EXAMPLE RUN:
	perl rna_seq_pipeline.pl -i /home/kanagarajm/samples_fq/ -o /mnt/state_lab/share/Manoj/rna_seq_out/ -g u -r 81214 --pairedEnd

REQUIRED ARGUMENTS:
	-i (input)				Directory containing all fastq files to be run through pipeline
	-o (output)				Directory where all output files will be organized and saved
	-g (genome build)			Genome build to be used 
							"u" for UCSC
							"e" for Ensembl
							"n" for NCBI
							"g10" for Gencode v10
							"g19" for Gencode v19
							"m2" for Gencode m2
								If using --altAnnotation option, then specify PATH of directory 
								containing necessary files for building transcriptome here instead
	-r (runID)				Unique runID used to identify and organize outputs from a given run

OPTIONS:
	--nocuffmerge			Use to skip running cuffmerge
	--altAnnotation			Use a different genome assembly. Specify directory where "Sequence" 
							and "Annotation" folders are located in -g argument
	--nodiscovery			Use to skip gene/transcript discovery and only quantify reference annotation
	--pairedEnd 			Use for if sequencing reads are paired-end, as opposed to single-end

Description:
	This script serves as the wrapper for the entire Tuxedo pipeline.
	It has been written to optimize the processing of multiple FASTQ 
	files produced via RNA sequencing by running them modularly in 
	parallel using the Oracle Sun Grid Engine (SGE).
	
	Together this collection of scripts can produce detailed expression 
	metrics and publication-ready graphs produced from cuffnorm/cuffdiff
	and cummeRbund, respectively, with just a single line of code from
	the command line.

	Within the given output directory, this script will create subdirectories
	that store the results of each component in the Tuxedo Suite. The output
	directory will also contain a log file that broadly documents the progress
	of the pipeline. More detailed logs can be found in each component's subdirectory.

	If you wish to run cuffdiff you must use the pipeline.pl script after this 
	pipeline has completed. For more information on using cuffdiff, enter
	"perl pipeline.pl --cd" at the commandline.

	^SCROLL UP FOR MORE INFORMATION^
HelpDocumentation

	exit;
}
else {
	print "\n\t\t\t>>>>>> ARGUMENTS LOADED <<<<<<\n\n";
}

# Parameter check
print <<ParamCheck;
Before running this script, please review the current parameters for TopHat and the Cuffsuite

TopHat:					-r 50 -p 8 --library-type fr-unstranded --solexa1.3-quals

Cufflinks:				-p 8 --library-type fr-unstranded --multi-read-correct --frag-bias-correct <GENOME>

Cuffmerge:				-p 8

Cuffquant:				-p 8 --library-type fr-unstranded --multi-read-correct --frag-bias-correct <GENOME>

Cuffnorm:				-p 8 --output-format cuffdiff

Cuffdiff:				-p 8 -u -b <GENOME>

Are these parameters suitable? [Y/N]

ParamCheck

my $paramCheck = <STDIN>;
if ($paramCheck !~ /y/i) {
	print "\nPlease edit 'run_pipeline.pl' manually to adjust the desired parameters.\n\n";
	exit;
}

print "Beginning pipeline...\n";

# Input checks
## Make sure genome type argument is valid. File path to the genome annotation directory is accepted if altAnnotation option is specified
unless ($altAnnotation){
	die "Invalid genome type\n" unless (($genomeType =~ /^[uen]$/i) or ($genomeType =~ /^g1[09]$/i) or ($genomeType =~ /^m2$/i));
} else {
	die "Invalid genome type\n" if (($genomeType =~ /^[uen]$/i) or ($genomeType =~ /^g1[09]$/i) or ($genomeType =~ /^m2$/i));
}

## Remove trailing forward slash if argument is a file path
$input =~ s/.$// if (substr($input, -1, 1) eq "/");
$output = $output . "/" if (substr($output, -1, 1) ne "/");
$genomeType =~ s/.$// if ($altAnnotation && (substr($genomeType, -1, 1) eq "/"));

print "Input validated.\n";

# Concatenate arguments string for use in rna_seq_pipeline shell script
my $arguments = "$input $output $genomeType $runID";
$arguments = $arguments . " --nocuffmerge" if($overrideCM);
$arguments = $arguments . " --altAnnotation" if($altAnnotation);
$arguments = $arguments . " --nodiscovery" if($overrideDisc);
$arguments = $arguments . " --pairedEnd" if($paired);

print "Ready for submission to SGE.\n";

# Call shell script to begin automated pipeline
`sh rna_seq_pipeline.sh $arguments`;



