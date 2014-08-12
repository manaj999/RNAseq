#!/usr/bin/Rscript

arg = commandArgs(trailingOnly = TRUE)

in_path = arg[1]
out_path = arg[2]

setwd(in_path)


if (file.exists(".RData")) {
	load(".RData")
}

# input file
fh = file("sample_names.txt",open="r")
lines=readLines(fh)

# output file for correlation values
#fileOut<-file("correlation_batch_out.txt")
sink("correlation_temp_out.txt")


for (i in 1:length(lines)){
	print(lines[i])

### NE ###
	# # create file names
	ne_plot<-paste(out_path,paste0(lines[i],"_ne.pdf"),sep="/")
	pdf(ne_plot)

	# # create merged data frame
	temp<-merge(subset(ncbi_uniq, select=c(lines[i])),subset(ensembl_uniq, select=c(lines[i])),by='row.names')
	colnames(temp)<-c('gene','x','y')

	# # make plot
	plot(log10(temp$x),log10(temp$y),xlim=c(-4,4),ylim=c(-4,4),main="Ensembl vs. NCBI")
	dev.off()

	# calculate correlation
	cat(paste0(lines[i],"_ne: ",cor(temp$x,temp$y)))
	cat("\n")

### UN ###
	un_plot<-paste(out_path,paste0(lines[i],"_un.pdf"),sep="/")
	pdf(un_plot)

	temp<-merge(subset(ucsc_uniq, select=c(lines[i])),subset(ncbi_uniq, select=c(lines[i])),by='row.names')
	colnames(temp)<-c('gene','x','y')

	plot(log10(temp$x),log10(temp$y),xlim=c(-4,4),ylim=c(-4,4),main="NCBI vs. UCSC")
	dev.off()

	cat(paste0(lines[i],"_un: ",cor(temp$x,temp$y)))
	cat("\n")

### UE ###
	ue_plot<-paste(out_path,paste0(lines[i],"_ue.pdf"),sep="/")
	pdf(ue_plot)

	temp<-merge(subset(ucsc_uniq, select=c(lines[i])),subset(ensembl_uniq, select=c(lines[i])),by='row.names')
	colnames(temp)<-c('gene','x','y')

	plot(log10(temp$x),log10(temp$y),xlim=c(-4,4),ylim=c(-4,4),main="Ensembl vs. UCSC")
	dev.off()

	cat(paste0(lines[i],"_ue: ",cor(temp$x,temp$y)))
	cat("\n")

### EG ###
	eg_plot<-paste(out_path,paste0(lines[i],"_eg.pdf"),sep="/")
	pdf(eg_plot)

	temp<-merge(subset(ensembl_uniq, select=c(lines[i])),subset(gencode_uniq, select=c(lines[i])),by='row.names')
	colnames(temp)<-c('gene','x','y')

	plot(log10(temp$x),log10(temp$y),xlim=c(-4,4),ylim=c(-4,4),main="Gencode vs. Ensembl")
	dev.off()

	cat(paste0(lines[i],"_eg: ",cor(temp$x,temp$y)))
	cat("\n")

### UG ###
	ug_plot<-paste(out_path,paste0(lines[i],"_ug.pdf"),sep="/")
	pdf(ug_plot)

	temp<-merge(subset(ucsc_uniq, select=c(lines[i])),subset(gencode_uniq, select=c(lines[i])),by='row.names')
	colnames(temp)<-c('gene','x','y')

	plot(log10(temp$x),log10(temp$y),xlim=c(-4,4),ylim=c(-4,4),main="Gencode vs. UCSC")
	dev.off()

	cat(paste0(lines[i],"_ug: ",cor(temp$x,temp$y)))
	cat("\n")

### NG ###
	ng_plot<-paste(out_path,paste0(lines[i],"_ng.pdf"),sep="/")
	pdf(ng_plot)

	temp<-merge(subset(ncbi_uniq, select=c(lines[i])),subset(gencode_uniq, select=c(lines[i])),by='row.names')
	colnames(temp)<-c('gene','x','y')

	plot(log10(temp$x),log10(temp$y),xlim=c(-4,4),ylim=c(-4,4),main="Gencode vs. NCBI")
	dev.off()

	cat(paste0(lines[i],"_ng: ",cor(temp$x,temp$y)))
	cat("\n")

	
}
close(fh)
sink()

save.image()
