# Write mqpar files for the PXD023211 (Guerrero-Castillo et al., BBA 2021)
# dataset.
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
accession = "PXD023211"

# read summary files
expt_names = paste0('MCP', 1:4)
summaries = map(expt_names, ~ {
  summary_file = paste0("data/mqpar/PXD023211/summary-", .x, ".txt.gz")
  summary = read.delim(summary_file) %>% 
    drop_na(Experiment) %>% 
    filter(Raw.file != 'Total') %>% 
    # drop one file that will not pass feature detection in MQ
    filter(!grepl('201209_CK_SGC_CCF5_TMT_37', Raw.file))
}) %>% setNames(expt_names)

# get filepths, replicates
files = map(summaries, 'Raw.file') %>% 
  unlist() %>% 
  paste0('.raw') %>% 
  file.path(args$raw_dir, .)
# fix some filepaths
missing_idxs = which(!file.exists(files))
files[missing_idxs][grepl('190529', files[missing_idxs])] %<>% 
  gsub("190529", "190527", .)
files[missing_idxs][grepl('201209', files[missing_idxs])] %<>% 
  gsub("_20201214233437", "", .)
replicates = rep(names(summaries), map_int(summaries, nrow))
fractions = map(summaries, ~ gsub("_2020.*$", "", .x$Raw.file) %>% 
                  strsplit('_') %>%
                  map_chr(last) %>%
                  # as.integer() %>% 
                  str_pad(2, pad = '0') %>% 
                  paste0('F', .)) %>% 
  unlist()

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
  
  ## TMT 6plex
  # change run type
  runtype_idx = which(grepl("lcmsRunType", mqpar))
  runtype_line = mqpar[runtype_idx] %>% 
    gsub(">.*<", paste0(">", 'Reporter ion MS2', "<"), .)
  mqpar[runtype_idx] = runtype_line
  # insert isobaric label info
  label_idxs = which(grepl("<(\\/)?isobaricLabels>", mqpar))
  label_start = label_idxs[1]
  label_info = readLines("data/mqpar/PXD027704/TMT-6plex.txt") 
  mqpar %<>% append(label_info, after = label_start)
  # fix the remaining reporter ion settings
  ## reporter mass tolerance
  mass_tol_idx = which(grepl("reporterMassTolerance", mqpar))
  mass_tol_line = mqpar[mass_tol_idx] %>% 
    gsub(">.*<", paste0(">", '0.003', "<"), .)
  mqpar[mass_tol_idx] = mass_tol_line
  ## reporter pif
  pif_idx = which(grepl("reporterPif", mqpar))
  pif_line = mqpar[pif_idx] %>% 
    gsub(">.*<", paste0(">", '0', "<"), .)
  mqpar[pif_idx] = pif_line
  ## reporter fraction
  reporter_fraction_idx = which(grepl("reporterFraction", mqpar))
  reporter_fraction_line = mqpar[reporter_fraction_idx] %>% 
    gsub(">.*<", paste0(">", '0', "<"), .)
  mqpar[reporter_fraction_idx] = reporter_fraction_line
  ## reporter base peak ratio
  base_peak_idx = which(grepl("reporterBasePeakRatio", mqpar))
  base_peak_line = mqpar[base_peak_idx] %>% 
    gsub(">.*<", paste0(">", '0', "<"), .)
  mqpar[base_peak_idx] = base_peak_line
  
  # write output
  output_filename = paste0("mqpar-", accession, "-", replicate, ".xml")
  if (!dir.exists(args$output_dir))
    dir.create(args$output_dir, recursive = T)
  output_file = file.path(args$output_dir, output_filename)
  writeLines(mqpar, output_file)
}
