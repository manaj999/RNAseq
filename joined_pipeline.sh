# args: 1 input, 2 output, 3 genometype, 4 runID, 5 cd, 6 nocuffmerge, 7 altAnnotation, 8 nodiscovery, 9 pairedEnd
qsub -V -N pipeBuild -pe parallel 8 -S /usr/bin/perl pipeline.pl -i $ARG1 -o $ARG2 -g $ARG3 -p 0 -r $ARG4 $ARG5 $ARG6 $ARG7 $ARG8 $ARG9;
BUILD_JID=(`qstat|grep "pipeBuild"|awk '{print $1;}'`);
echo $BUILD_JID;

qsub -hold_jid $BUILD_JID -V -l h=ihg-node-1 -N pipeThCl -S /usr/bin/perl pipeline.pl -i $ARG1 -o $ARG2 -g $ARG3 -p 1 -r $ARG4 $ARG5 $ARG6 $ARG7 $ARG8 $ARG9;
#sleep 10;
THCL_JID=(`qstat|grep "sub_pipe_1"|awk '{print $1;}'`);
echo $THCL_JID;

# qsub -hold_jid $THCL_JID -pe parallel 8 -V -N pipelineCm -S /usr/bin/perl pipeline.pl -i $ARG1 -o $ARG2 -g $ARG3 -p 2 -r $ARG4 $ARG5 $ARG6 $ARG7 $ARG8 $ARG9;
# CM_JID=(`qstat|grep "pipelineCm"|awk '{print $1;}'`);
# echo $CM_JID;

# qsub -hold_jid $CM_JID -V -l h=ihg-node-1 -N pipelineCq -S /usr/bin/perl pipeline.pl -i $ARG1 -o $ARG2 -g $ARG3 -p 3 -r $ARG4 $ARG5 $ARG6 $ARG7 $ARG8 $ARG9;
# sleep 10;
# CQ_JID=(`qstat|grep "sub_pipe_2"|awk '{print $1;}'`);
# echo $CQ_JID;

# qsub -hold_jid $CQ_JID -pe parallel 8 -V -N pipelineCnCb -S /usr/bin/perl pipeline.pl -i $ARG1 -o $ARG2 -g $ARG3 -p 4 -r $ARG4 $ARG5 $ARG6 $ARG7 $ARG8 $ARG9;
# CNCB_JID=(`qstat|grep "pipelineCnCb"|awk '{print $1;}'`);
# echo $CNCB_JID;

#cuff diff eventually?

# qsub [first qsub script].sh;
# ARRAY_JID=(`qstat|grep [name of job]|awk '{print $1;}'`); #This requires you to know the name of your job ie. the value of your '-N' qsub option
# echo $ARRAY_JID; #for verifcation
# qsub -hold_jid $ARRAY_JID [second qsub script].sh # submits job2 and queues it as hqw

# #repeat lines 2 and 4 for subsequent additional jobs to be queued.
