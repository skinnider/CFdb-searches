# Write mqpar files for the PXD013809 (Kerr et al., 2020) dataset.
setwd("~/git/CFdb-searches")
options(stringsAsFactors = F)
library(argparse)

# parse arguments
parser = ArgumentParser(prog = 'write-mqpars.R')
# parser$add_argument('--raw_dir', type = 'character', required = T,
#                     help = 'directory containing RAW files')
parser$add_argument('--mqpar_file', type = 'character', required = T,
                    help = 'base mqpar file to edit')
parser$add_argument('--output_dir', type = 'character', required = T,
                    help = 'output directory to write XML files to')
args = parser$parse_args()

# load remaining libraries
library(tidyverse)
library(magrittr)

# set accession
accession = "PXD013809"

# read design table
design = read.delim("data/mqpar/PXD013809/PCPSILAC_summary.txt.gz") %>%
  # remove rows from bottom
  drop_na(Experiment)

# extract replicates
files = design$Raw.file
patts = c('rep1' = 'CK-160916',
          'rep2' = 'CK-2017-01',
          'rep3' = 'CK-(.*?)-170501',
          'rep4' = 'CK-170615')
replicates = map_chr(files, ~ { 
  file = .
  names(patts)[map_lgl(patts, ~ grepl(., file))] 
})

# extract fractions
fractions = character(length = length(replicates))
## rep1
fr1 = files[replicates == 'rep1'] %>%
  strsplit('_') %>% 
  map_chr(2)
fr1_lett = substr(fr1, 1, 1)
fr1_num = substr(fr1, 2, nchar(fr1))
fr1 = fr1_num %>% 
  as.numeric() %>% 
  str_pad(pad = '0', side = 'left', width = 2) %>% 
  paste0(fr1_lett, .)
fractions[replicates == 'rep1'] = fr1
## rep2
fr2 = files[replicates == 'rep2'] %>%
  gsub("^.*-", "", .) %>%
  strsplit('_') %>% 
  map_chr(2)
fr2_lett = substr(fr2, 1, 1)
fr2_num = substr(fr2, 2, nchar(fr2))
fr2 = fr2_num %>% 
  as.numeric() %>% 
  str_pad(pad = '0', side = 'left', width = 2) %>% 
  paste0(fr2_lett, .)
fractions[replicates == 'rep2'] = fr2
## rep3
fr3 = files[replicates == 'rep3'] %>%
  strsplit('-') %>%
  map_chr(2) 
fr3_lett = substr(fr3, 1, 1)
fr3_num = substr(fr3, 2, nchar(fr3))
fr3 = fr3_num %>% 
  as.numeric() %>% 
  str_pad(pad = '0', side = 'left', width = 2) %>% 
  paste0(fr3_lett, .)
fractions[replicates == 'rep3'] = fr3
## rep4
fr4 = files[replicates == 'rep4'] %>%
  strsplit('_') %>%
  map_chr(2) 
fr4_lett = substr(fr4, 1, 1)
fr4_num = substr(fr4, 2, nchar(fr4))
fr4 = fr4_num %>% 
  as.numeric() %>% 
  str_pad(pad = '0', side = 'left', width = 2) %>% 
  paste0(fr4_lett, .)
fractions[replicates == 'rep4'] = fr4

# create design table
design = data.frame(file = design$Raw.file, 
                    replicate = replicates,
                    experiment = fractions) %>%
  # flag repeats
  group_by(replicate, experiment) %>%
  mutate(fraction = row_number()) %>%
  ungroup() %>% 
  # reconstruct filepaths
  mutate(file = file.path(args$raw_dir, paste0(file, '.d')))

# save csv
write.csv(design, "data/mqpar/PXD013809/design.csv", row.names = F)

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
