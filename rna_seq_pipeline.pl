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

print "Beginning pipeline...\n";

my ( $input, $output, $genomeType, $runID, $overrideCM, $altAnnotation, $overrideDisc, $paired );

GetOptions(	
	'i=s' => \$input,
	'o=s' => \$output,
	'g=s' => \$genomeType,
	'r=i' => \$runID,
	
	'nocuffmerge' => \$overrideCM,
	'altAnnotation' => \$altAnnotation,
	'nodiscovery' => \$overrideDisc,
	'pairedEnd' => \$paired
) or die "Incorrect input and/or output path!\n";

print "Arguments loaded.\n";

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



