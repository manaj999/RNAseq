# Wrapper script intended to prevent Cuffnorm and CummeRbund from running until all
## Samples have been processed through Cuffquant

sleep 60;
CN_JID=(`qstat|grep "sub_pipe_s"|awk '{print $1;}'`);

qsub -hold_jid $CN_JID -V -N pipeCnCb -S /usr/bin/perl pipeline.pl -i $1 -o $2 -g $3 -p 4 -r $4 $5 $6 $7 $8 $9;