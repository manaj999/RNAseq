#!/bin/bash
#$ -N run_pipeline
#$ -M manoj.kanagaraj@ucsf.edu
#$ -j y
#$ -S /usr/bin/perl
#$ -cwd
#$ -V
#$ -pe parallel 8

SAMPLE_DIR=$ARG1;
#SAMPLE_DIR=/home/kanagarajm/fq_batch/;
SAMPLE_LIST=($SAMPLE_DIR/$ARG6);
INDEX=$((SGE_TASK_ID-1));
INPUT_FILE=${SAMPLE_LIST[$INDEX]};
#echo $INPUT_FILE;
perl run_pipeline.pl -i $INPUT_FILE -o $ARG2 -g $ARG3 -p $ARG4 -r $ARG5