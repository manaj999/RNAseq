#!/usr/bin/perl
use strict;
use warnings;

# USAGE:
	## perl repl-script.pl <OUTPUT_NAME> <# REPLICATES>


my $replicates;
if (!$ARGV[1]){
	$replicates = 1;
}
else {
	$replicates = $ARGV[1];
}


my $file = $ARGV[0];
open (SUB, '>', $file);

print SUB <<ShellScript;
#!/bin/bash

#Name of Job - will appear in qstat
#\$ -N sub_pipe_f

#Join your STDOUT and STDERR reports (if processing 50+ files this option is handy but not required)
#\$ -j y

#Path of executable (in this case Perl)
#\$ -S /usr/bin/perl

#Use current working directory
#\$ -cwd

#Export environment variables to qsub
#\$ -V

#Number of threads to use per CPU (50 of the 52 nodes have 16 threads available)
#\$ -pe parallel 8

# This submit script provides both flexibility and efficiency. 
# It enables multiple jobs to be run in parallel on the Sun Grid Engine without compromising performance.
# It also preserves flexibility by allowing the user to specify options at the commandline in 'pipeline.pl'.

#defining SGE_INDEX and input files
	## Locate directory with all fastQ files to be run through pipeline
SAMPLE_DIR=\$ARG1;
ShellScript

for (my $i=1; $i <= $replicates; $i++) {
	print SUB "SAMPLE_LIST_N".$i."_R1=(\$SAMPLE_DIR/*_N".$i."_R1.\$ARG6);\n";
}

print SUB <<ShellScript;
# Iterate through each file in SAMPLE_LIST and make perl call for run_pipeline.pl
INDEX=\$((SGE_TASK_ID-1));
ShellScript

for (my $i=1; $i <= $replicates; $i++) {
	print SUB "INPUT_FILE_N".$i."_R1=\${SAMPLE_LIST_N".$i."_R1[\$INDEX]};\n";
}

my $input_R1 = "";

for (my $i=1; $i <= $replicates; $i++) {
	$input_R1 = $input_R1 . "\$INPUT_FILE_N".$i."_R1,";
}

$input_R1 =~ s/.$// if (substr($input_R1, -1, 1) eq ",");

print SUB <<ShellScript;
#Script to execute
perl run_pipeline.pl -i $input_R1 -o \$ARG2 -g \$ARG3 -p \$ARG4 -r \$ARG5 -m \$ARG7 -n \$ARG8
ShellScript

close(SUB);
