# Rtest included in order to analyze the correlation of gene expression from RNAseq data across genome annotations.

# STEPS TO GENERATE PAIRWISE CORRELATION PLOTS:
	## The steps below include example commands from comparing UCSC, NCBI, Ensembl and Gencode v10. 
	## If you plan to use another annotation, simply add in the appropriate genes.fpkm_tracking file
	## and replicate these steps with the additional annotation.

# 1. AWK to trim a common gene list. 
## INPUT = *_genes.fpkm_tracking from cuffnorm/cuffdiff
## Must also have the 'extract.awk' script in your working directory

	# Extract short gene names
	awk '$5!~"-"{print $5}' ncbi_genes.fpkm_tracking > list.ncbi
	awk '$5!~"-"{print $5}' ensembl_genes.fpkm_tracking > list.ensembl
	awk '$5!~"-"{print $5}' ucsc_genes.fpkm_tracking > list.ucsc
	awk '$5!~"-"{print $5}' gencode_genes.fpkm_tracking > list.gencode

	# Create a merged version of the above lists, including only genes common to all annotations
	awk 'FNR==NR {a[$1];next} $1 in a' list-ensembl list-ncbi > anno2_genes.txt
	awk 'FNR==NR {a[$1];next} $1 in a' anno2_genes.txt list-ucsc > anno3_genes.txt
	awk 'FNR==NR {a[$1];next} $1 in a' anno3_genes.txt list-gencode > anno4_genes.txt

	# Using this merged gene list, extract entries from the tracking files that correspond to these genes
	awk -f extract.awk anno4_genes.txt ncbi_genes.fpkm_tracking > trimmed-ncbi.txt
	awk -f extract.awk anno4_genes.txt ensembl_genes.fpkm_tracking > trimmed-ensembl.txt
	awk -f extract.awk anno4_genes.txt ucsc_genes.fpkm_tracking > trimmed-ucsc.txt
	awk -f extract.awk anno4_genes.txt gencode_genes.fpkm_tracking > trimmed-gencode.txt

# 2. Create a text file containing the names of each sample called 'sample_names.txt'
## Example:
	### HSB103.DFC_FPKM
	###	HSB103.HIP_FPKM
	### ...
	###	HSB113.DFC_FPKM

# 3. R to load unique genes from each annotation
## INPUT = trimmed-*.txt files from part 1 corresponding to each annotation used for analysis

	# Launch R shell and read files into R
	ncbi<-read.table("trimmed-ncbi.txt", header=TRUE, sep="\t")
	ensembl<-read.table("trimmed-ensembl.txt", header=TRUE, sep="\t")
	ucsc<-read.table("trimmed-ucsc.txt", header=TRUE, sep="\t")
	gencode<-read.table("trimmed-gencode.txt", header=TRUE, sep="\t")

	# Remove duplicate entries
	ncbi_uniq=ncbi[!duplicated(ncbi[,5]),]
	ensembl_uniq=ensembl[!duplicated(ensembl[,5]),]
	ucsc_uniq=ucsc[!duplicated(ucsc[,5]),]
	gencode_uniq=gencode[!duplicated(gencode[,5]),]

# 4. Run Rscript to generate plots and correlation coefficients for all pairwise combinations of samples from each annotation
## INPUT = *_uniq files from part 3 corresponding to each annotation used for analysis
## IMPORTANT: if using annotations other than those listed here, it is necessary to edit "correlation_batch.R" in order
	### for it to be compatible with the desired annotations.
	### The script is fairly straightforward but must be manually revised based on the annotations being compared.

	# Run script
	Rscript correlation_batch.R <INPUT> <OUTPUT>

## Input to correlation_batch.R must be the working directory where the processes from steps 1-3 were conducted.


