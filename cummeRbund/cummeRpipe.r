#!/usr/bin/Rscript

arg = commandArgs(trailingOnly = TRUE)

setwd(arg[1])
load(".RData")
library(cummeRbund)
cuff<-readCufflinks()


# Density plot
dens_plot<-paste(arg[2],paste0("csDensity_",arg[3],".pdf"),sep="/")
pdf(dens_plot)
csDensity(genes(cuff))
dev.off()

# Dendrogram
dendro<-paste(arg[2],paste0("csDendro_",arg[3],".pdf"),sep="/")
pdf(dendro)
csDendro(genes(cuff))
dev.off()

# PCA plot
pca<-paste(arg[2],paste0("PCAplot_",arg[3],".pdf"),sep="/")
pdf(pca)
PCAplot(genes(cuff),"PC1","PC2")
dev.off()

# MDS plot
mds<-paste(arg[2],paste0("MDSplot_",arg[3],".pdf"),sep="/")
pdf(mds)
MDSplot(genes(cuff))
dev.off()


save.image()
