# Write mqpar files for the PXD016521 (Protasoni et al., EMBO J 2020) dataset.
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

# define accession
accession = "PXD016521"

# read README from PRIDE
readme = read.delim("data/mqpar/PXD016521/README.txt") %>% 
  # RAW files only
  filter(TYPE == "RAW")

# break down filenames
## part 1 e.g. PRO4052A234MA3
gsub("Digestof.*$", "", readme$NAME) %>% n_distinct
gsub("Digestof.*$", "", readme$NAME) %>% substr(nchar(.) - 2, nchar(.)) %>% table
gsub("Digestof.*$", "", readme$NAME) %>% gsub("A.*$", "", .) %>% table
## PRO4052: 256 = 64*4
gsub("Digestof.*$", "", readme$NAME) %>% gsub("^.*[0-9]A", "", .) %>% gsub("M.*$", "", .) %>% table
gsub("Digestof.*$", "", readme$NAME) %>% gsub("^.*[0-9]A", "", .) %>% gsub("M.*$", "", .) %>% n_distinct
## summary:
#' - PRO4052 is probably complexome
#' - all MA3
#' - middle A probably fraction #?
gsub("^.*Digestof", "", readme$NAME) %>% strsplit('-') %>% map_chr(2) %>% table
table(
  gsub("^.*Digestof", "", readme$NAME) %>% strsplit('-') %>% map_chr(2),
  gsub("Digestof.*$", "", readme$NAME) %>% gsub("A.*$", "", .)
)
gsub("^.*Digestof", "", readme$NAME) %>% strsplit('-') %>% map_chr(3) %>% table
gsub("^.*Digestof", "", readme$NAME) %>% strsplit('-') %>% map_chr(4) %>% table
gsub("^.*Digestof", "", readme$NAME) %>% strsplit('-') %>% map_chr(5) %>% table

# put it all together
readme0 = readme %>% 
  ## limit to complexome
  filter(grepl("PRO4052", NAME)) %>% 
  ## remove one standalone replicate
  filter(!grepl("180309", NAME))
replicates = gsub("^.*Digestof", "", readme0$NAME) %>% 
  strsplit('-') %>%
  map_chr(4)
fractions = gsub("Digestof.*$", "", readme0$NAME) %>% 
  gsub("^.*[0-9]A", "", .) %>% 
  gsub("M.*$", "", .) 
fractions2 = gsub("^.*Digestof", "", readme0$NAME) %>% 
  strsplit('-') %>% 
  map_chr(3)
df = data.frame(file = readme0$NAME,
                replicate = replicates,
                fraction1 = fractions, 
                fraction2 = fractions2) %>% 
  arrange(replicate, fraction1, fraction2) %>% 
  group_by(replicate) %>% 
  mutate(fraction1a = as.integer(fraction1) - min(as.integer(fraction1)) + 1,
         fraction2a = as.integer(fraction2) - min(as.integer(fraction2)) + 1) %>% 
  ungroup()
df %>% group_by(replicate) %>% summarise(mean = mean(fraction1a == fraction2a))
# View(df)

# create design table
design = df %>% 
  dplyr::rename(experiment = fraction1a) %>%
  dplyr::select(-starts_with('fraction')) %>% 
  mutate(experiment = as.character(experiment) %>% 
           str_pad(width = 2, pad = '0') %>% 
           paste0('F', .)) %>% 
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
