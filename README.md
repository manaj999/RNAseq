#### **Pipeline for RNAseq using TUXEDO protocols**

### **Scripts required in workin directory:**
```
rna_seq_pipeline.pl
rna_seq_pipeline.sh

pipeline.pl
run_pipeline.pl

submit_1.sh
submit-paired_1.sh
submit_2.sh

cn_hold.sh
cummeRpipe.r
```
----------------------------------------------------------------------------------
### **Description:**
```
	This script serves as the wrapper for the entire Tuxedo pipeline.
	It has been written to optimize the processing of multiple FASTQ 
	files produced via RNA sequencing by running them modularly in 
	parallel using the Oracle Sun Grid Engine (SGE).
	
	Together this collection of scripts can produce detailed expression 
	metrics and publication-ready graphs produced from cuffnorm/cuffdiff
	and cummeRbund, respectively, with just a single line of code from
	the command line.

	Within the given output directory, this script will create subdirectories
	that store the results of each component in the Tuxedo Suite. The output
	directory will also contain a log file that broadly documents the progress
	of the pipeline. More detailed logs can be found in each component's subdirectory.

	If you wish to run cuffdiff you must use the pipeline.pl script after this 
	pipeline has completed. For more information on using cuffdiff, enter
	"perl pipeline.pl --cd" at the commandline.
```
----------------------------------------------------------------------------------
### **Usage:**
```
**GENERAL:**
	perl rna_seq_pipeline.pl -i <INPUT> -o <OUTPUT> -g <GENOME> -r <RUNID> <OPTIONS>

**EXAMPLE RUN:**
	perl rna_seq_pipeline.pl -i /home/kanagarajm/samples_fq/ -o /mnt/state_lab/share/Manoj/rna_seq_out/ -g u -r 81214 --pairedEnd

**REQUIRED ARGUMENTS:**
	-i (input)				Directory containing all fastq files to be run through pipeline
	-o (output)				Directory where all output files will be organized and saved
	-g (genome build)			Genome build to be used 
							"u" for UCSC
							"e" for Ensembl
							"n" for NCBI
							"g10" for Gencode v10
							"g19" for Gencode v19
							"m2" for Gencode m2
								If using --altAnnotation option, then specify PATH of directory 
								containing necessary files for building transcriptome here instead
	-r (runID)				Unique runID used to identify and organize outputs from a given run

**OPTIONS:**
	--nocuffmerge			Use to skip running cuffmerge
	--altAnnotation			Use a different genome assembly. Specify directory where "Sequence" 
							and "Annotation" folders are located in -g argument
	--nodiscovery			Use to skip gene/transcript discovery and only quantify reference annotation
	--pairedEnd 			Use for if sequencing reads are paired-end, as opposed to single-end
```