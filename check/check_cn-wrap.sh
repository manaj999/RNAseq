#cn_wrap.sh

sleep 60;
CN_JID=(`qstat|grep "sub_pipe_s"|awk '{print $1;}'`);
#qsub -hold_jid $CN_JID -pe parallel 8 -V -N pipeCnCb -S /usr/bin/perl check-pipeline.pl -i /home/kanagarajm/fq_batch/ -o /mnt/state_lab/share/Manoj/pipeline_RNAseq_out/ -g u -p 4 -r 888;

qsub -hold_jid $CN_JID -V -N pipeCnCb -S /usr/bin/perl check-pipeline.pl -i $1 -o $2 -g $3 -p 4 -r $4 $5 $6 $7 $8 $9;