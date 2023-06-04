# Write mqpar files for the PXD002640 (Gazestani et al., PLoS Pathogens 2016) 
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
accession = "PXD002640"

# set up design
#' ^SAL1018: whole cell, GG, 48 files
#' ^SAL1328: mitochondrial, GG, 47 files
#' ^sal71_cyto: whole cell, IEX, 19 files
#' ^sal71_mito: mitochondrial, IEX, 20 files
#' note: many fractions have repeats
files = list.files(args$raw_dir, full.names = F) %>%
  extract(grepl('\\.raw$', ., ignore.case = T))

# assign replicates
replicates = rep(NA, length(files))
replicates[grepl('^SAL1018', files)] = 'WC-GG'
replicates[grepl('^SAL1328', files)] = 'Mito-GG'
replicates[grepl('^SAL71_cyto', files)] = 'Cyto-IEX'
replicates[grepl('^SAL71_mito', files)] = 'Mito-IEX'

# assign MaxQuant 'experiments'
experiments = rep(NA, length(files))
iex_idxs = which(endsWith(replicates, 'IEX'))
gg_idxs = which(endsWith(replicates, 'GG'))
## first, parse IEX filenames
iex_expts = gsub("^.*o_|_2015.*$", "", files[iex_idxs])
## enforce leading zeroes
iex_expts = map_chr(iex_expts, ~ {
  fractions = unlist(strsplit(., '_'))
  fractions = stringr::str_pad(fractions, width = 2, pad = '0')
  paste0(fractions, collapse = '_') %>%
    paste0('F', .)
})
experiments[iex_idxs] = iex_expts
## second, parse GG filenames
gg_expts = map_chr(strsplit(files[gg_idxs], '_'), 2) %>%
  ## enforce leading zeroes 
  stringr::str_pad(width = 2, pad = '0') %>%
  paste0('F', .)
experiments[gg_idxs] = gg_expts

# assign MaxQuant 'fractions'
design = data.frame(filename = files, replicate = replicates,
                    experiment = experiments) %>%
  group_by(replicate, experiment) %>%
  mutate(fraction = row_number()) %>%
  ungroup()

# write design file to git
write.csv(design, "data/mqpar/PXD002640/design.csv", row.names = F)

# write mqpar file for each replicate
replicates = unique(design$replicate)
for (replicate in replicates) {
  message("processing replicate ", replicate, " ...")
  
  # extract fractions
  design0 = filter(design, replicate == !!replicate)
  files = file.path(args$raw_dir, design0$filename)
  experiments = design0$experiment
  fractions = design0$fraction
  
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
