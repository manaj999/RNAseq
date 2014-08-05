qsub [first qsub script].sh;
ARRAY_JID=(`qstat|grep [name of job]|awk '{print $1;}'`); #This requires you to know the name of your job ie. the value of your '-N' qsub option
echo $ARRAY_JID; #for verifcation
qsub -hold_jid $ARRAY_JID [second qsub script].sh # submits job2 and queues it as hqw

#repeat lines 2 and 4 for subsequent additional jobs to be queued.
