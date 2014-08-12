
# sh rna_seq_pipeline.sh <INPUT> <OUTPUT> <GENOME> <RUNID> <OPTIONS>
## This shell script serves to coordinate the submissions of sub-scripts that execute
	### each step of the Tuxedo pipeline
## By managing the steps in this modular fashion, users can process 
	### multiple RNAseq FASTQ files simultaneously and efficiently

echo "Part 0: Submitting transcriptome build step.";

qsub -V -N pipeBuild -l h=ihg-node-1 -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 0 -r $4 $5 $6 $7 $8;
BUILD_JID=(`qstat|grep pipeBuild|awk '{print $1;}'`);
echo $BUILD_JID;

echo "Part 1: Submitting TopHat and Cufflinks (optional) steps.";

qsub -V -hold_jid $BUILD_JID -l h=ihg-node-1 -N pipeThCl -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 1 -r $4 $5 $6 $7 $8;
# The sleep command is necessary because part 1 of pipeline.pl calls a submit script that the next step must wait for.
## Thus, it is necessary to wait some time until the jobs to begin TopHat have been received by the SGE.
echo "Sleeping for 60 seconds... Please be patient.";
sleep 60; 
THCL_JID=(`qstat|grep "sub_pipe_f"|awk '{print $1;}'`);
echo $THCL_JID;

echo "Part 2: Submitting Cuffmerge (optional) step.";
qsub -hold_jid $THCL_JID -V -N pipeCm -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 2 -r $4 $5 $6 $7 $8;
CM_JID=(`qstat|grep "pipeCm"|awk '{print $1;}'`);
echo $CM_JID;

echo "Part 3: Submitting Cuffquant step.";
qsub -hold_jid $CM_JID -V -l h=ihg-node-1 -N pipeCq -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 3 -r $4 $5 $6 $7 $8;
CQ_JID=(`qstat|grep "pipeCq"|awk '{print $1;}'`);
echo $CQ_JID;

echo "Part 4: Submitting Cuffnorm and CummeRbund steps.";
qsub -hold_jid $CQ_JID -V -l h=ihg-node-27 -N wrapCn -S /bin/sh cn_hold.sh $1 $2 $3 $4 $5 $6 $7 $8;

echo "All jobs have been submitted to the SGE. Please use the 'qstat' command to monitor their progress.";