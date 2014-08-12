# This script is intended to make GENCODE annotations compatible with TopHat

# It removes the inclusion of the "gene" featuer type in column 3 of the gtf downloaded from GENCODE
	## See for more information: https://groups.google.com/forum/#!topic/tuxedo-tools-users/FTKA4qozJIc
# This script should complete within a few seconds

# Usage

	awk -f prepare-GENCODE.awk [original GTF] > [new GTF name]

# Example
	awk -f prepare-GENCODE.awk old_genes.gtf > genes.gtf