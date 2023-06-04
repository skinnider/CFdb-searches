# Write mqpar files for the PXD005968 (Crozier et al., MCP 2017) dataset.
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
accession = "PXD005968"

# read templates
templ1 = read.delim("data/mqpar/PXD005968/SEC300-experimentalDesignTemplate.txt")
templ2 = read.delim("data/mqpar/PXD005968/SEC1000-experimentalDesignTemplate.txt")
templ3 = read.delim("data/mqpar/PXD005968/SAX-experimentalDesignTemplate.txt")
table(gsub("_.*$", "", templ1$Experiment))
table(gsub("_.*$", "", templ2$Experiment))
table(gsub("_.*$", "", templ3$Experiment))
#' SEC300: 5 replicates, 48 fractions
#' SEC1000: 5 replicates, 48 fractions
#' SAX: 1 replicate, 96 fractions

# split up by replicate 
design = bind_rows(templ1 %>% mutate(column = 'SEC300'), 
                   templ2 %>% mutate(column = 'SEC1000'),
                   templ3 %>% mutate(column = 'SAX')) %>%
  mutate(replicate = paste0(column, '_', gsub("_.*$", "", Experiment)))

# filter to files that exist
design %<>%
  mutate(filepath = file.path(args$raw_dir, paste0(Name, '.raw')),
         exists = file.exists(filepath)) %>%
  filter(exists)

# write mqpar file for each replicate
replicates = unique(design$replicate)
for (replicate in replicates) {
  message("processing replicate ", replicate, " ...")
  
  # extract fractions
  design0 = filter(design, replicate == !!replicate)
  filenames = paste0(design0$Name, '.raw')
  files = file.path(args$raw_dir, filenames)
  experiments = design0$Experiment
  fractions = design0$Fraction
  
  # make sure all files exist
  exists = file.exists(files)
  if (!all(exists)) {
    warning(replicate, ": ", sum(!exists), " of ", length(exists),
            " files do not exist")
    # remove those files
    design0 %<>% extract(file.exists(files), )
  }
  
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
    new_params = rep(param_line, length(files))
    ## remove old parameter lines
    mqpar %<>% extract(-c(param_start:param_end))
    ## insert new ones
    mqpar %<>% append(new_params, after = param_start - 1) 
  }
  
  # remove old fractions and replace with new ones
  mqpar %<>% extract(-c(fraction_start:fraction_end))
  new_fractions = map_chr(fractions, ~ gsub(">.*<", paste0(">", ., "<"), 
                                            dplyr::first(fraction_lines)))
  mqpar %<>% append(new_fractions, after = fraction_start - 1) 
  
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
  output_filename = paste0("mqpar-", accession, "-", replicate, ".xml")
  if (!dir.exists(args$output_dir))
    dir.create(args$output_dir, recursive = T)
  output_file = file.path(args$output_dir, output_filename)
  writeLines(mqpar, output_file)
}
