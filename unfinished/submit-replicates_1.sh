#!/bin/bash

#Name of Job - will appear in qstat
#$ -N sub_pipe_f

#Join your STDOUT and STDERR reports (if processing 50+ files this option is handy but not required)
#$ -j y

#Path of executable (in this case Perl)
#$ -S /usr/bin/perl

#Use current working directory
#$ -cwd

#Export environment variables to qsub
#$ -V

#Number of threads to use per CPU (50 of the 52 nodes have 16 threads available)
#$ -pe parallel 8

# This submit script provides both flexibility and efficiency. 
# It enables multiple jobs to be run in parallel on the Sun Grid Engine without compromising performance.
# It also preserves flexibility by allowing the user to specify options at the commandline in 'pipeline.pl'.

#defining SGE_INDEX and input files
	## Locate directory with all fastQ files to be run through pipeline
SAMPLE_DIR=$ARG1;
SAMPLE_LIST_R1=($SAMPLE_DIR/*_R1.$ARG6);
SAMPLE_LIST_R2=($SAMPLE_DIR/*_R2.$ARG6);

# Iterate through each file in SAMPLE_LIST and make perl call for run_pipeline.pl
INDEX=$((SGE_TASK_ID-1));
INPUT_FILE_R1=${SAMPLE_LIST_R1[$INDEX]};
INPUT_FILE_R2=${SAMPLE_LIST_R2[$INDEX]};

#Script to execute
perl run_pipeline.pl -i $INPUT_FILE_R1 -o $ARG2 -g $ARG3 -p $ARG4 -r $ARG5 -m $ARG7 -n $ARG8 -e $INPUT_FILE_R2
