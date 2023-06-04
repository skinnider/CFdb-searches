# Write mqpar files for the PXD002320 (Wan et al., Dicty) dataset, 
# based on the human defaults. 
setwd("~/git/CFdb-searches")
options(stringsAsFactors = F)
library(argparse)

# parse arguments
parser = ArgumentParser(prog = 'write-mqpars.R')
parser$add_argument('--metazoa_dir', type = 'character', required = T,
                    help = paste('directory containing files from', 
                                 'http://metazoa.med.utoronto.ca/'))
parser$add_argument('--raw_dir', type = 'character', required = T,
                    help = 'directory containing RAW files')
parser$add_argument('--mqpar_file', type = 'character', required = T,
                    help = 'mqpar file to edit')
parser$add_argument('--output_dir', type = 'character', required = T,
                    help = 'output directory to write XML files to')
args = parser$parse_args()

# load remaining libraries
library(tidyverse)
library(magrittr)

# set accession
accession = "PXD002320"

# repeat for each input file
input_files = list.files(args$metazoa_dir, pattern = "FDR", full.names = T)
for (input_file in input_files) {
  # get experiment name
  expt_name = gsub("\\..*$", "", basename(input_file))
  message("processing experiment: ", expt_name, " ...")
  
  # read fractions
  fractions = readLines(input_file, n = 1) %>%
    strsplit("\t") %>%
    unlist() %>%
    extract(-c(1:2))
  
  # omit two fractions from one experiment: corrupt files
  if (expt_name == "Dd_HCW_2")
    fractions %<>% extract(!grepl("P2A06|P2A07", .))
  
  # set input files
  files = paste0(fractions, ".raw")
  # set experiments
  experiments = gsub("^.*_", "", fractions)
  if (n_distinct(experiments) != n_distinct(fractions))
    stop("manually investigate experiments")
  
  # make sure all files exist
  exists = file.exists(file.path(args$raw_dir, files))
  if (!all(exists))
    stop(sum(!exists), " of ", length(exists), " files do not exist")
  
  # re-read the base mqpar file
  mqpar = readLines(args$mqpar_file)
  
  # get filepaths and experiments
  filepath_idxs = which(grepl("<(\\/)?filePaths>", mqpar))
  filepath_start = filepath_idxs[1] + 1
  filepath_end = filepath_idxs[2] - 1
  filepath_lines = mqpar[filepath_start:filepath_end]
  expt_idxs = which(grepl("<(\\/)?experiments>", mqpar))
  expt_start = expt_idxs[1] + 1
  expt_end = expt_idxs[2] - 1
  expt_lines = mqpar[expt_start:expt_end]
  
  # fix dimensions
  dim_params = c("referenceChannel",
                 "paramGroupIndices",
                 "ptms",
                 "fractions")
  for (dim_param in dim_params) {
    param_idxs = which(grepl(paste0("<(\\/)?", dim_param, ">"), mqpar))
    param_start = param_idxs[1] + 1
    param_end = param_idxs[2] - 1
    param_lines = mqpar[param_start:param_end]
    if (n_distinct(param_lines) > 1) 
      stop("manually investigate paramter: ", dim_params)
    param_line = unique(param_lines)
    new_params = rep(param_line, length(experiments))
    ## remove old parameter lines
    mqpar %<>% extract(-c(param_start:param_end))
    ## insert new ones
    mqpar %<>% append(new_params, after = param_start - 1) 
  }
  
  # replace all fractions with '1'
  fraction_idxs = which(grepl("<(\\/)?fractions>", mqpar))
  fraction_start = fraction_idxs[1] + 1
  fraction_end = fraction_idxs[2] - 1
  fraction_lines = mqpar[fraction_start:fraction_end]
  fraction_lines %<>% gsub(">.*<", paste0(">", "1", "<"), .)
  
  # remove old experiments and replace with new ones
  mqpar %<>% extract(-c(expt_start:expt_end))
  new_expts = map_chr(experiments, ~ gsub(">.*<", paste0(">", ., "<"), 
                                          dplyr::first(expt_lines)))
  mqpar %<>% append(new_expts, after = expt_start - 1) 
  
  # remove old filepaths and replace with new ones
  mqpar %<>% extract(-c(filepath_start:filepath_end))
  new_files = map_chr(files, ~ gsub(">.*<", paste0(">", ., "<"), 
                                    dplyr::first(filepath_lines)))
  mqpar %<>% append(new_files, after = filepath_start - 1) 
  
  # write output
  output_filename = paste0("mqpar-", accession, "-", expt_name, ".xml")
  if (!dir.exists(args$output_dir))
    dir.create(args$output_dir, recursive = T)
  output_file = file.path(args$output_dir, output_filename)
  writeLines(mqpar, output_file)
}

# add a third file, for Dd_HCW_3
expt_name = "Dd_HCW_3"
message("processing experiment: ", expt_name, " ...")

# read fractions from RAW files directly
files = list.files(args$raw_dir, pattern = "*.raw$") %>%
  extract(grepl("^WAN130*", .))
fractions = gsub("\\.raw$", "", files)
# set experiments
experiments = gsub("^.*_", "", fractions)
if (n_distinct(experiments) != n_distinct(fractions))
  stop("manually investigate experiments")

# make sure all files exist
exists = file.exists(file.path(args$raw_dir, files))
if (!all(exists))
  stop(sum(!exists), " of ", length(exists), " files do not exist")

# re-read the base mqpar file
mqpar = readLines(args$mqpar_file)

# get filepaths and experiments
filepath_idxs = which(grepl("<(\\/)?filePaths>", mqpar))
filepath_start = filepath_idxs[1] + 1
filepath_end = filepath_idxs[2] - 1
filepath_lines = mqpar[filepath_start:filepath_end]
expt_idxs = which(grepl("<(\\/)?experiments>", mqpar))
expt_start = expt_idxs[1] + 1
expt_end = expt_idxs[2] - 1
expt_lines = mqpar[expt_start:expt_end]

# fix dimensions
dim_params = c("referenceChannel",
               "paramGroupIndices",
               "ptms",
               "fractions")
for (dim_param in dim_params) {
  param_idxs = which(grepl(paste0("<(\\/)?", dim_param, ">"), mqpar))
  param_start = param_idxs[1] + 1
  param_end = param_idxs[2] - 1
  param_lines = mqpar[param_start:param_end]
  if (n_distinct(param_lines) > 1) 
    stop("manually investigate paramter: ", dim_params)
  param_line = unique(param_lines)
  new_params = rep(param_line, length(experiments))
  ## remove old parameter lines
  mqpar %<>% extract(-c(param_start:param_end))
  ## insert new ones
  mqpar %<>% append(new_params, after = param_start - 1) 
}

# replace all fractions with '1'
fraction_idxs = which(grepl("<(\\/)?fractions>", mqpar))
fraction_start = fraction_idxs[1] + 1
fraction_end = fraction_idxs[2] - 1
fraction_lines = mqpar[fraction_start:fraction_end]
fraction_lines %<>% gsub(">.*<", paste0(">", "1", "<"), .)

# remove old experiments and replace with new ones
mqpar %<>% extract(-c(expt_start:expt_end))
new_expts = map_chr(experiments, ~ gsub(">.*<", paste0(">", ., "<"), 
                                        dplyr::first(expt_lines)))
mqpar %<>% append(new_expts, after = expt_start - 1) 

# remove old filepaths and replace with new ones
mqpar %<>% extract(-c(filepath_start:filepath_end))
new_files = map_chr(files, ~ gsub(">.*<", paste0(">", ., "<"), 
                                  dplyr::first(filepath_lines)))
mqpar %<>% append(new_files, after = filepath_start - 1) 

# write output
output_filename = paste0("mqpar-", accession, "-", expt_name, ".xml")
if (!dir.exists(args$output_dir))
  dir.create(args$output_dir, recursive = T)
output_file = file.path(args$output_dir, output_filename)
writeLines(mqpar, output_file)
