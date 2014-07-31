#!/bin/bash
#$ -N run_pipeline
#$ -M manoj.kanagaraj@ucsf.edu
#$ -j y
#$ -S /usr/bin/perl
#$ -cwd
#$ -V
#$ -pe parallel 8

# This submit script provides both flexibility and efficiency. 
# It enables multiple jobs to be run in parallel on the Sun Grid Engine without compromising performance.
# It also preserves flexibility by allowing the user to specify options at the commandline in 'pipeline.pl'.

# Locate directory with all fastQ files to be run through pipeline
SAMPLE_DIR=$ARG1;
SAMPLE_LIST=($SAMPLE_DIR/$ARG6);

# Iterate through each file in SAMPLE_LIST and make perl call for run_pipeline.pl
INDEX=$((SGE_TASK_ID-1));
INPUT_FILE=${SAMPLE_LIST[$INDEX]};

perl run_pipeline.pl -i $INPUT_FILE -o $ARG2 -g $ARG3 -p $ARG4 -r $ARG5 -m $ARG7