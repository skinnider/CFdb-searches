# Write mqpar files for the PXD002892 (Scott et al., MSB 2017) dataset.
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
accession = "PXD002892"

# read files
files = list.files(args$raw_dir, pattern = "*.raw$", full.names = T) %>%
  # remove TAILS
  extract(!grepl("tails", ., ignore.case = T)) %>%
  # remove incomplete replicate(s)
  # extract(!grepl("20130426|20130501|BN_PCP_SILAC_mito", .)) %>%
  # extract(!grepl("20130426|20130501|PCP_SEC_mito", .)) %>%
  extract(!grepl("PCP_SEC_mito|BN_PCP_SILAC_mito", .)) %>%
  # remove reference mixture
  extract(!grepl("reference_mix", .)) %>%
  # remove 'failed' fractions
  extract(!grepl("failed", .))

# reconstruct experimental design
replicate_patts = c(
  'untreated' = '20130426|20130501', # 'PCP_SEC_mito',
  'BN1' = '20130826',
  'BN2' = 'BNPAGE_apoptosis_mito_rep2',
  'BN3' = '4hr_Mito_rep3',
  'SEC1' = '130715_PCP_SILAC_apoptosis',
  'SEC2' = '20130906_SEC',
  'SEC3' = 'SEC_apoptosis_bio_rep3'
)
replicate_ids = map_chr(basename(files), ~ {
  filename = .
  names(which(map_lgl(replicate_patts, ~ grepl(., filename))))
})

# now get 'experiments' (fractions)
fraction_pos = stringr::str_locate(gsub("fracti0n", "fraction", files),
                                   'fraction')
experiments = map_chr(seq_along(files), ~
                        substr(gsub("fraction_|fracti0n", "fraction", files[.]), 
                               fraction_pos[., 1],
                               fraction_pos[., 2] + 2))

# finally, randomly tag 'fractions' (repeats)
design = data.frame(replicate = replicate_ids, experiment = experiments,
                    file = files) %>%
  group_by(replicate, experiment) %>%
  mutate(fraction = row_number()) %>%
  ungroup() %>%
  dplyr::select(replicate, experiment, fraction, file)

# remove files that break LFQ normalization
# design %<>%
#   filter(!basename(file) %in% 
#            c('Nsco_20130826_MITO_BN_PAGE_4hr_fraction01.raw'))

# save this file in git
write.csv(design, "data/mqpar/PXD002892/design.csv", row.names = F)

# write mqpar file for each replicate
replicates = unique(design$replicate)
for (replicate in replicates) {
  message("processing replicate ", replicate, " ...")
  
  # extract fractions
  design0 = filter(design, replicate == !!replicate)
  files = design0$file
  experiments = design0$experiment
  fractions = design0$fraction
  
  # make sure all files exist
  exists = file.exists(files)
  if (!all(exists))
    stop(sum(!exists), " of ", length(exists), " files do not exist")
  
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
  
  # change multiplicity
  mqpar[grepl("multiplicity", mqpar)] %<>% 
    gsub(">.*<", paste0(">", 3, "<"), .)
  
  # add SILAC labels
  labelmod_idxs = which(grepl("<(\\/)?labelMods>", mqpar))
  labelmod_start = labelmod_idxs[1] + 1
  labelmod_end = labelmod_idxs[2] - 1
  labelmod_lines = mqpar[labelmod_start:labelmod_end]
  mqpar %<>% extract(-c(labelmod_start:labelmod_end))
  new_lines = c("            <string />",
                "            <string>Arg6;Lys4</string>",
                "            <string>Arg10;Lys8</string>")
  mqpar %<>% append(new_lines, after = labelmod_start - 1) 
  
  # write output
  output_filename = paste0("mqpar-", accession, "-", replicate, ".xml")
  if (!dir.exists(args$output_dir))
    dir.create(args$output_dir, recursive = T)
  output_file = file.path(args$output_dir, output_filename)
  writeLines(mqpar, output_file)
}
