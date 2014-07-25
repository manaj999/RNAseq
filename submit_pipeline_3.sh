#!/bin/bash
#$ -N run_pipeline
#$ -M manoj.kanagaraj@ucsf.edu
#$ -j y
#$ -S /usr/bin/perl
#$ -cwd
#$ -V
#$ -pe parallel 8
#$ -t 1-16
#$ -tc 16
SAMPLE_DIR=/home/kanagarajm/fq_batch/;
SAMPLE_LIST=($SAMPLE_DIR/*.fq.gz);
INDEX=$((SGE_TASK_ID-1));
INPUT_FILE=${SAMPLE_LIST[$INDEX]};
#echo $INPUT_FILE;
perl run_pipeline_batch.pl -i $INPUT_FILE -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 1 -r 72414