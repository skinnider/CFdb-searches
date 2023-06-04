# Write a table linking every file that was searched to information about the
# experiment.
setwd("~/git/CFdb-searches")
options(stringsAsFactors = F)
library(tidyverse)
library(magrittr)

# first, read experiments table
expts = read.csv("data/experiments.csv")

# now, for every accession/replicate, read all files
files = data.frame()
for (idx in seq_len(nrow(expts))) {
  accession = expts$Accession[idx]
  replicate = expts$Replicate[idx] %>%
    gsub("-medium|-heavy|-[1-6]$", "", .)
  replicate_mqpar = fct_recode(replicate,
                               'BN3to12_RAW' = 'BN3to12',
                               'BN4to16_RAW' = 'BN4to16',
                               'Ghosts_DDM_BiobasicSEC-2' = 'Ghosts_6061_DDM_BiobasicSEC',
                               'Hemolysate_old_9330_SEC' = 'Hemolysate_9330_old_SEC',
                               'whole_rbc_IP_lysis_6840' = 'whole_rbc_IP_lysis',
                               'Hemolysate_8994_IEX-3' = 'Hemolysate_8994_IEX') %>% 
    as.character() %>% 
    suppressWarnings()
  
  # read mqpar file
  mqpar_file = paste0('data/mqpar/', accession, '/mqpar-', accession, '-',
                      replicate_mqpar, '.xml')
  if (!file.exists(mqpar_file)) {
    warning('skipping file: ', mqpar_file)
    next
  }
  mqpar = readLines(mqpar_file)
  
  # get files
  filepath_idxs = which(grepl("<(\\/)?filePaths>", mqpar))
  filepath_start = filepath_idxs[1] + 1
  filepath_end = filepath_idxs[2] - 1
  filepath_lines = mqpar[filepath_start:filepath_end]
  filepaths = gsub("<(\\/)?string>", "", filepath_lines) %>% trimws()
  filenames = basename(filepaths) %>%
    # also fix for Windows
    gsub("^.*\\\\", "", .)
  
  # add to files data frame
  suppressWarnings(
    rows <- data.frame(File = filenames) %>% cbind(expts[idx, ]))
  files %<>% bind_rows(rows)
}
# rearrange columns
files %<>% dplyr::select(Author, Year, Accession, Replicate,
                         Quantitation, Species, File)

# collapse redundant files
files0 = files %>%
  group_by(Author, Year, Accession, Quantitation, Species, File) %>%
  dplyr::slice(1) %>%
  ungroup()

# write csv
write.csv(files0, "data/files.csv", row.names = F)
