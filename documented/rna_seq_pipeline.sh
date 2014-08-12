

# args: 1 input, 2 output, 3 genometype, 4 runID, 5 cd, 6 nocuffmerge, 7 altAnnotation, 8 nodiscovery, 9 pairedEnd

qsub -V -N pipeBuild -l h=ihg-node-1 -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 0 -r $4 $5 $6 $7 $8 $9;
BUILD_JID=(`qstat|grep pipeBuild|awk '{print $1;}'`);
echo $BUILD_JID;

qsub -V -hold_jid $BUILD_JID -l h=ihg-node-1 -N pipeThCl -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 1 -r $4 $5 $6 $7 $8 $9;
sleep 60; # can adjust this to make longer later to be safe
THCL_JID=(`qstat|grep "sub_pipe_f"|awk '{print $1;}'`);
echo $THCL_JID;

qsub -hold_jid $THCL_JID -V -N pipeCm -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 2 -r $4 $5 $6 $7 $8 $9;
CM_JID=(`qstat|grep "pipeCm"|awk '{print $1;}'`);
echo $CM_JID;

qsub -hold_jid $CM_JID -V -l h=ihg-node-1 -N pipeCq -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 3 -r $4 $5 $6 $7 $8 $9;
CQ_JID=(`qstat|grep "pipeCq"|awk '{print $1;}'`);
echo $CQ_JID;

# #wrap cn
qsub -hold_jid $CQ_JID -V -l h=ihg-node-27 -N wrapCn -S /bin/sh cn_hold.sh $1 $2 $3 $4 $5 $6 $7 $8 $9;