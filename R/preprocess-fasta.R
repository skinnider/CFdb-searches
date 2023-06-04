# Preprocess protein FASTA files for database search by filtering proteins
# 10 aa or shorter.
setwd("~/git/CFdb-searches")
options(stringsAsFactors = F)
library(tidyverse)
library(magrittr)
library(seqinr)

# list files
files = list.files("data/fasta/raw", pattern = "*.gz", full.names = T)
for (file in files) {
  # read fasta file
  fa = read.fasta(file, seqtype = 'AA')
  before = length(fa)

  # remove small proteins
  keep = lengths(fa) > 10
  fa = fa[keep]
  after = length(fa)
  
  # write
  filename = gsub("\\.gz", "", basename(file))
  output_file = file.path("data/fasta/filtered", filename)
  write.fasta(fa, names = gsub(">", "", map_chr(fa, getAnnot)), output_file)
  system(paste("gzip --force", output_file))

  message("wrote ", after, " of ", before, " proteins for ", filename, 
          " (", format(100 * after / before, digits = 4), "%)")
}
