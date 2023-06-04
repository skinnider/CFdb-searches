# Write mqpar files for the PXD013322 (McWhite et al., Cell 2020) 
# Brassica oleracea (2/2) dataset.
setwd("~/git/CFdb-searches")
options(stringsAsFactors = F)
library(argparse)

# parse arguments
parser = ArgumentParser(prog = 'write-mqpars.R')
parser$add_argument('--raw_dir', type = 'character', required = T,
                    help = 'directory containing RAW files')
parser$add_argument('--mqpar_file', type = 'character', required = T,
                    help = 'base mqpar file to edit')
parser$add_argument('--output_dir', type = 'character', required = T,
                    help = 'output directory to write XML files to')
args = parser$parse_args()

# load remaining libraries
library(tidyverse)
library(magrittr)

# set accession
accession = "PXD013322"

# read files
files = list.files(args$raw_dir, pattern = "*\\.raw$", full.names = F)

# extract replicate and fractions
replicates = ifelse(grepl("BroccoliNE_WWC", files), "braol_nuc1", 
                    "braol_nuc2")
fractions = strsplit(basename(files), '_') %>%
  map_chr(3) %>%
  gsub("a", "", .) %>%
  paste0("F", .)

# create design table
design = data.frame(file = files,
                    replicate = replicates,
                    experiment = fractions) %>%
  group_by(replicate, experiment) %>%
  mutate(fraction = row_number()) %>%
  ungroup()

# write mqpar file for each replicate
for (replicate in unique(design$replicate)) {
  message("processing replicate ", replicate, " ...")
  
  # extract fractions
  design0 = filter(design, replicate == !!replicate)
  files0 = design0$file
  experiments0 = design0$experiment
  fractions0 = design0$fraction
  
  # re-read the base mqpar file
  mqpar = readLines(args$mqpar_file)
  
  # get filepaths, experiments, and fractions
  filepath_idxs = which(grepl("<(\\/)?filePaths>", mqpar))
  filepath_start = filepath_idxs[1] + 1
  filepath_end = filepath_idxs[2] - 1
  filepath_lines = mqpar[filepath_start:filepath_end]
  expt_idxs = which(grepl("<(\\/)?experiments>", mqpar))
  expt_start = expt_idxs[1] + 1
  expt_end = expt_idxs[2] - 1
  expt_lines = mqpar[expt_start:expt_end]
  fraction_idxs = which(grepl("<(\\/)?fractions>", mqpar))
  fraction_start = fraction_idxs[1] + 1
  fraction_end = fraction_idxs[2] - 1
  fraction_lines = mqpar[fraction_start:fraction_end]
    
  # fix dimensions
  dim_params = c("referenceChannel",
                 "paramGroupIndices",
                 "ptms")
  for (dim_param in dim_params) {
    param_idxs = which(grepl(paste0("<(\\/)?", dim_param, ">"), mqpar))
    param_start = param_idxs[1] + 1
    param_end = param_idxs[2] - 1
    param_lines = mqpar[param_start:param_end]
    if (n_distinct(param_lines) > 1) 
      stop("manually investigate paramter: ", dim_params)
    param_line = unique(param_lines)
    new_params = rep(param_line, length(files0))
    ## remove old parameter lines
    mqpar %<>% extract(-c(param_start:param_end))
    ## insert new ones
    mqpar %<>% append(new_params, after = param_start - 1) 
  }

  # remove old fractions and replace with new ones
  mqpar %<>% extract(-c(fraction_start:fraction_end))
  new_fractions = map_chr(fractions0, ~ gsub(">.*<", paste0(">", ., "<"), 
                                             dplyr::first(fraction_lines)))
  mqpar %<>% append(new_fractions, after = fraction_start - 1) 
    
  # remove old experiments and replace with new ones
  mqpar %<>% extract(-c(expt_start:expt_end))
  new_expts = map_chr(experiments0, ~ gsub(">.*<", paste0(">", ., "<"), 
                                           dplyr::first(expt_lines)))
  mqpar %<>% append(new_expts, after = expt_start - 1) 

  # remove old filepaths and replace with new ones
  mqpar %<>% extract(-c(filepath_start:filepath_end))
  new_files = map_chr(files0, ~ gsub(">.*<", paste0(">", ., "<"), 
                                    dplyr::first(filepath_lines)))
  mqpar %<>% append(new_files, after = filepath_start - 1) 
  
  # write output
  output_filename = paste0("mqpar-", accession, "-", replicate, ".xml")
  if (!dir.exists(args$output_dir))
    dir.create(args$output_dir, recursive = T)
  output_file = file.path(args$output_dir, output_filename)
  writeLines(mqpar, output_file)
}
