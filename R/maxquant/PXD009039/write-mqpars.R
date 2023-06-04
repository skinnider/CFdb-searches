# Write mqpar files for the PXD009039 (Hillier et al., Cell Rep 2019) dataset.
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
accession = "PXD009039"

# set up design
files = list.files(args$raw_dir, full.names = F)

# match each file to a species
species_map = c('Pk' = 'know',
                'Pf' = 'falc',
                'Pb' = 'berg')
species_matches = map(files, ~ { 
  file = .
  names(species_map)[map_lgl(species_map, ~ grepl(., file, ignore.case = T))]
})
## from MaxQuant results on PRIDE:
#'   CH09BN: berghei, +mouse
#'   CH10AN: berghei, +mouse
#'   CH12AN: berghei, +mouse
#' also, must be 0-0.1-1, based on remaining datasets
species_matches[lengths(species_matches) == 0] = 'Pb'
# convert species to a character vector
species = species_matches %>% 
  extract(lengths(.) > 0) %>%
  map_chr(identity)

# match each file to a detergent
detergent_map = c('0' = 'zero',
                  '0.1' = 'point',
                  '1' = 'one')
detergent_matches = map(files, ~ { 
  file = .
  names(detergent_map)[map_lgl(detergent_map, ~ grepl(., file, ignore.case = T))]
})
# just replace missing detergent matches with NAs for now
detergent_matches[lengths(detergent_matches) == 0] = NA
# convert detergent to a character vector
detergent = detergent_matches %>% 
  extract(lengths(.) > 0) %>%
  map_chr(identity)

# extract replicate from filename
replicate = strsplit(files, '_') %>%
  map_chr(2) %>%
  substr(., 1, 4)

# extract fraction from filename
fractions = gsub("\\.raw$", "", files) %>%
  gsub("^.*-", "", .) %>%
  # what to do with fractions marked 'X'? 
  gsub("R|X", "", .)

# create design data frame and tag MQ 'fractions'
design = data.frame(file = files,
                    species = species,
                    detergent = detergent,
                    replicate = replicate,
                    experiment = fractions) %>%
  # remove one RAW file of unclear origin
  filter(startsWith(replicate, 'CH')) %>%
  # tag MaxQuant fractions
  group_by(species, detergent, replicate, experiment) %>%
  mutate(fraction = row_number()) %>%
  ungroup() %>%
  # arrange for pretty printing
  arrange(replicate, experiment) %>%
  # remove one corrupt file
  filter(basename(file) != 'OT25cm_CH24_Berg_Point-06.raw')
 
# write design file to git
write.csv(design, "data/mqpar/PXD009039/design.csv", row.names = F)

# write mqpar file for each replicate
replicates = unique(design$replicate)
for (replicate in replicates) {
  message("processing replicate ", replicate, " ...")
  
  # extract fractions
  design0 = filter(design, replicate == !!replicate)
  files = file.path(args$raw_dir, design0$file)
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
