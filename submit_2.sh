#!/bin/bash

#Name of Job - will appear in qstat
#$ -N sub_pipe_s

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


#defining SGE_INDEX and input files
	## Locate directory with all th-out directories produced from Part 1 of the pipeline
SAMPLE_DIR=$ARG1;
SAMPLE_LIST=($SAMPLE_DIR/$ARG6);

# Iterate through each file in SAMPLE_LIST and make perl call for run_pipeline.pl
INDEX=$((SGE_TASK_ID-1));
INPUT_FILE=${SAMPLE_LIST[$INDEX]};

#Script to execute
perl run_pipeline.pl -i $INPUT_FILE -o $ARG2 -g $ARG3 -p $ARG4 -r $ARG5 -m $ARG7 -n $ARG8
