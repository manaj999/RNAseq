#!/usr/bin/Rscript

# Rscript correlation_gencode.r /Users/Manoj/Desktop/genes_matrix_csv/ /Users/Manoj/Desktop/genes_matrix_csv/out/

# USAGE: used specifically for calculating correlation coefficients and plots between gencode internal and external

arg = commandArgs(trailingOnly = TRUE)
in_path = arg[1]
out_path = arg[2]

setwd(in_path)

if (file.exists(".RData")) {
	load(".RData")
}

# input file
fh = file("sample_names_proc.txt",open="r")
lines=readLines(fh)

# output file for correlation values
#fileOut<-file("correlation_batch_out.txt")
sink("correlation_proc_out.txt")


for (i in 1:length(lines)){

### NE ###
	# # create file names
	#proc_plot<-paste(out_path,paste0(lines[i],"_proc.pdf"),sep="/")

	proc_plot <- file.path(out_path,paste0(lines[i],"_proc.pdf"), sep = "/"))

	pdf(file=proc_plot)

	# # create merged data frame
	temp<-merge(subset(gencode_compare, select=c(lines[i])),subset(gencode_compare_proc, select=c(lines[i])),by='row.names')
	colnames(temp)<-c('gene','lab','proc')

	# adjust values
	temp$lab[temp$lab<10e-4]<-1
	temp$proc[temp$lab==1]<-1

	# # make plot
	plot(log10(temp$lab),log10(temp$proc),xlim=c(-4,4),ylim=c(-4,4),main="Externally Processed Data vs. Internally Processed Data")
	dev.off()

	# calculate correlation
	cat(paste0(lines[i],": ",cor(temp$lab,temp$proc)))
	cat("\n")


	
}
close(fh)
sink()

save.image()
