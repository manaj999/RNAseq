#!/bin/bash
#$ -N run_pipeline
#$ -M manoj.kanagaraj@ucsf.edu
#$ -j y
#$ -S /usr/bin/perl
#$ -cwd
#$ -V
#$ -pe parallel 8
#$ -t 1-20
#$ -tc 20
SAMPLE_DIR=/mnt/speed/kanagarajM/pipeline_batch/th-out;
SAMPLE_LIST=($SAMPLE_DIR/th-out_*_72414);
INDEX=$((SGE_TASK_ID-1));
INPUT_FILE=${SAMPLE_LIST[$INDEX]};
#echo $INPUT_FILE;
perl run_pipeline.pl -i $INPUT_FILE -o /mnt/speed/kanagarajM/pipeline_batch/ -g u -p 2 -r 72414