# Write mqpar files for the PXD030050 (Sae-Lee et al., Cell Rep 2022) 
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
accession = "PXD030050"

# read files
files = list.files(args$raw_dir, pattern = "*\\.raw$", full.names = FALSE,
                   recursive = TRUE) %>% 
  # ignore cross-linked
  extract(!grepl("Xlink", ., ignore.case = TRUE)) %>% 
  # ignore two files that MQ cannot normalize
  extract(!grepl("Hemolysate6569_SEC_ctrlRNaseA_15_01052018", .) &
          !grepl("Plasma_3126_BioSepSEC_44_1a_10252018", .))

# extract replicates
replicates = dirname(files)

# extract fraction indices
split = split(basename(files), replicates)
fr1 = split$Ghosts_1006_1percent_TX100_HIC %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("a", "", .) %>% as.integer()
fr2 = split$Ghosts_1percentDDM %>% strsplit('_') %>% map_chr(3) %>% as.integer()
fr3 = split$Ghosts_1percentDDM__IEX_3801 %>% strsplit('_') %>% map_chr(6) %>% 
  as.integer()
fr4 = split$Ghosts_1percentDDM_3801_BiobasicSEC %>% strsplit('_') %>% 
  map_chr(5) %>% as.integer()
fr5 = split$ghosts_3801_1DDM_ingel %>% strsplit('_') %>% map_chr(5) %>%
  gsub("a", "", .) %>% as.integer()
fr6 = split$Ghosts_3801_DDM_WWC %>% strsplit('_') %>% map_chr(5) %>%
  gsub("a", "", .) %>% as.integer()
fr7 = split$Ghosts_6061_DDM_HIC %>% strsplit('_') %>% map_chr(5) %>%
  gsub("a", "", .) %>% as.integer()
fr8 = split$ghosts_6840_1DDM_SEC %>% strsplit('_') %>% map_chr(5) %>% 
  gsub("a", "", .) %>% as.integer()
fr9 = split$ghosts_8994_2_5DIBMA_BioBasic_SEC %>% strsplit('_') %>% 
  map_chr(7) %>% gsub("a", "", .) %>% as.integer()
fr10 = split$ghosts_8994_2_5DIBMA_BioSep_SEC %>% strsplit('_') %>% 
  map_chr(7) %>% gsub("a", "", .) %>% as.integer()
fr11 = split$`Ghosts_DDM_BiobasicSEC-2` %>% strsplit('_') %>% map_chr(5) %>% 
  gsub("a|b", "", .) %>% as.integer()
fr12 = split$`Ghosts_old_9330_BioSep_SEC_TX-100` %>% strsplit('_') %>%
  map_chr(7) %>% as.integer()
fr13 = split$Hemolysate_6061_HIC %>% strsplit('_') %>% map_chr(4) %>% 
  as.integer() 
fr14 = split$Hemolysate_6569_old_SEC_Ctrl %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("a|b", "", ., ignore.case = TRUE) %>% as.integer()
fr15 = split$Hemolysate_6569_old_SEC_RNAseA %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("a", "", .) %>% as.integer()
fr16 = split$Hemolysate_6569_young_SEC_Ctrl %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("a", "", .) %>% as.integer()
fr17 = split$Hemolysate_6569_young_SEC_RNAseA %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("a", "", .) %>% as.integer()
fr18 = split$`Hemolysate_8994_IEX-3` %>% strsplit('_') %>% map_chr(4) %>% 
  as.integer()
fr19 = split$Hemolysate_8994_WWC %>% strsplit('_') %>% map_chr(4) %>% 
  as.integer()
fr20 = split$Hemolysate_IEX %>% strsplit('_') %>% map_chr(3) %>% 
  as.integer()
fr21 = split$Hemolysate_IEX_2 %>% strsplit('_') %>% map_chr(4) %>% 
  as.integer()
fr22 = split$Hemolysate_old_9330_SEC %>% strsplit('_') %>% map_chr(5) %>% 
  gsub("a", "", .) %>% as.integer()
fr23 = split$Hemolysate_SEC %>% strsplit('_') %>% map_chr(3) %>% 
  as.integer()
fr24 = split$Hemolysate6569_SEC_ctrlRNaseA %>% strsplit('_') %>% map_chr(4) %>% 
  gsub("a|b", "", .) %>% as.integer()
fr25 = split$Hemolysate6569_SEC_RNaseA %>% strsplit('_') %>% map_chr(4) %>% 
  as.integer()
fr26 = split$Plasma_SEC %>% strsplit('_') %>% 
  map_chr(~ extract(.x, length(.x) - 2)) %>% as.integer()
fr27 = split$Platelet_SEC %>% strsplit('_') %>% map_chr(4) %>% as.integer()
fr28 = split$RBC_ghosts1_WWC %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("\\.raw", "", .) %>% as.integer()  
fr29 = split$RBC_lysate_Pierce_IP_lysis_6840_HIC %>% strsplit('_') %>%
  map_chr(8) %>% gsub("a", "", .) %>% as.integer()
fr30 = split$RBC_soluble_WWC %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("\\.raw", "", .) %>% as.integer()
fr31 = split$whole_rbc_IP_lysis_6840 %>% strsplit('_') %>% map_chr(6) %>% 
  gsub("a", "", .) %>% as.integer()
# merge
fractions = map(seq_len(31), ~ get(paste0("fr", .x))) %>% unlist()
# confirm no NAs
stopifnot(!any(is.na(fractions)))
# format: three digits, leading F
fractions %<>% str_pad(3, pad = '0') %>% paste0('F', .)

# create design table
design = data.frame(file = unlist(split),
                    replicate = rep(names(split), lengths(split)),
                    experiment = fractions) %>% 
  group_by(replicate, experiment) %>% 
  mutate(fraction = row_number()) %>% 
  ungroup()

# manually vet files with fraction>1
design %>%
  group_by(replicate, experiment) %>% 
  filter(n() > 1) %>% 
  as.data.frame() %>%
  arrange(replicate, experiment)

# write mqpar file for each replicate
for (replicate in unique(design$replicate)) {
  message("processing replicate ", replicate, " ...")
  
  # extract fractions
  design0 = filter(design, replicate == !!replicate)
  files0 = design0$file %>%
    # re-add base directory
    file.path(args$raw_dir, .)
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
