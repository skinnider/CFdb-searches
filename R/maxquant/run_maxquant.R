#' Search a proteomics dataset using MaxQuant.
#' 
#' This script takes as input (i) a basic mqpar.xml file with filenames, 
#' experiments, and fractions set up, (ii) a directory containing the raw
#' mass spec files, (iii) a FASTA database, and (iv) the path to the 
#' MaxQuant binary.
#' 
#' It also takes as input any specific parameters used to run the MaxQuant 
#' search.
setwd("~/git/CFdb-searches")
options(stringsAsFactors = F)
library(argparse)

# parse arguments
parser = ArgumentParser(prog = 'run_maxquant.R',
                        description = 'search a PCP dataset with MaxQuant')
parser$add_argument('--mqpar_file', type = 'character', required = T,
                    help = 'the mqpar.xml file to use for the search')
parser$add_argument('--fasta_file', type = 'character', required = T,
                    help = 'the FASTA file to use for the search')
parser$add_argument('--base_dir', type = 'character', required = T,
                    help = 'the directory containing MS files to be searched')
parser$add_argument('--mq_dir', type = 'character', required = T,
                    help = 'the directory containing MaxQuantCmd.exe')
## optional: directories
parser$add_argument('--output_dir', type = 'character', help = paste0(
  'the directory to write results to; defaults to {base_dir}/combined'))
parser$add_argument('--search_dir', type = 'character', help = paste0(
  'the directory to write search files to; defaults to {base_dir}/search'))
parser$add_argument('--tmp_dir', type = 'character', help = paste0(
  'the directory to write tmp folder to; defaults to {base_dir}/tmp'))
## optional: parameters
parser$add_argument('--specificity', type = 'character', default = 'specific',
                    choices = c('specific', 'semispecific', 'semispecific_2'),
                    help = 'peptide cleavage specificity')
parser$add_argument('--no_mbr', action = 'store_true', 
                    help = 'disable match between runs')
parser$add_argument('--no_second_peptide', action = 'store_true', 
                    help = 'disable second peptide search')
parser$add_argument('--carbamidomethylation', default = 'fixed',
                    choices = c('fixed', 'variable', 'none'))
parser$add_argument('--cysteine_nem', default = 'none',
                    choices = c('fixed', 'variable', 'none'))
parser$add_argument('--deamidation', action = 'store_true', help = paste(
  'enable deamidation as a variable modification, and use for quant'))
parser$add_argument('--phosphorylation', type = 'character', default = 'FALSE',
                    help = 'enable phosphorylation as a variable modification, and use for quant')
parser$add_argument('--lysc', type = 'character', default = 'FALSE',
                    help = 'add LysC cleavage')
parser$add_argument('--no_trypsin', type = 'character', default = 'FALSE',
                    help = 'disable trypsin cleavage')
parser$add_argument('--disable_lfq_norm', type = 'character', default = 'FALSE',
                    help = 'disable LFQ normalization')
parser$add_argument('--ms_ms_tol_da', type = 'double', default = NULL,
                    help = 'MS/MS tolerance, in Da')
parser$add_argument('--ms_ms_tol_ppm', type = 'double', default = NULL,
                    help = 'MS/MS tolerance, in ppm')
parser$add_argument('--n_threads', type = 'integer', default = 16,
                    help = 'number of threads to run search on')
# parse arguments
args = parser$parse_args()
print(args)
# convert character to boolean
args$phosphorylation = as.logical(args$phosphorylation)
args$disable_lfq_norm = as.logical(args$disable_lfq_norm)
args$lysc = as.logical(args$lysc)
args$no_trypsin = as.logical(args$no_trypsin)

# print date and time
print("current time:")
print(Sys.time())

# escape all spaces
args$mqpar_file = gsub(" ", "\\\\ ", args$mqpar_file)
args$fasta_file = gsub(" ", "\\\\ ", args$fasta_file)
args$base_dir = gsub(" ", "\\\\ ", args$base_dir)
args$mq_dir = gsub(" ", "\\\\ ", args$mq_dir)
if (!is.null(args$output_dir))
  args$output_dir = gsub(" ", "\\\\ ", args$output_dir)
if (!is.null(args$search_dir))
  args$search_dir = gsub(" ", "\\\\ ", args$search_dir)
if (!is.null(args$tmp_dir))
  args$tmp_dir = gsub(" ", "\\\\ ", args$tmp_dir)

# check files
if (!file.exists(args$mqpar_file))
  stop("mqpar file does not exist: ", args$mqpar_file)
if (!file.exists(args$fasta_file))
  stop("mqpar file does not exist: ", args$fasta_file)
if (!dir.exists(args$base_dir))
  stop("base directory does not exist: ", args$base_dir)
if (!dir.exists(args$mq_dir))
  stop("MaxQuant directory does not exist: ", args$mq_dir)

# check search directories
if (is.null(args$output_dir))
  args$output_dir = file.path(args$base_dir, "combined")
if (is.null(args$search_dir))
  args$search_dir = file.path(args$base_dir, "search")
if (is.null(args$tmp_dir))
  args$tmp_dir = file.path(args$base_dir, "tmp")

# check MaxQuant binary
mq_bin = file.path(args$mq_dir, "MaxQuantCmd.exe")
if (!file.exists(mq_bin))
  stop("MaxQuant binary does not exist: ", mq_bin)

# load remaining libraries
library(tidyverse)
library(magrittr)
library(R.utils)

# set up function to fix filepaths for windows
fix_windows_filepath = function(filepath) {
  gsub("\\/", "\\\\", filepath)
}

# read the base mqpar file
mqpar = readLines(args$mqpar_file)

# first, unzip and copy FASTA file into bin/conf
fasta_dir = file.path(args$mq_dir, "conf")
fasta_dest = file.path(fasta_dir, basename(args$fasta_file))
if (!file.exists(gsub("\\.gz$", "", fasta_dest))) {
  file.copy(args$fasta_file, fasta_dest)
  gunzip(fasta_dest, remove = T, overwrite = T)
}
fasta_dest = gsub("\\.gz$", "", fasta_dest)
# on Windows, change forward slashes to backwards ones
if (Sys.info()[['sysname']] == "Windows") {
  fasta_dest %<>% fix_windows_filepath()
}
# mqpar: modify FASTA filepath
# replace in a somewhat convoluted manner to avoid backslash gsub
line = mqpar[grepl("fastaFilePath", mqpar)]
line1 = gsub(">.*$", "", line)
line3 = gsub("^.*<", "", line)
line2 = paste0(">", fasta_dest, "<")
mqpar[grepl("fastaFilePath", mqpar)] = paste0(line1, line2, line3)

# mqpar: change FASTA header parse rule
mqpar[grepl("identifierParseRule", mqpar)] %<>%
  gsub(">.*<", paste0(">", '>.*\\\\|(.*)\\\\|', "<"), .)

# mqpar: change MS filepaths
filepath_idxs = which(grepl("<(\\/)?filePaths>", mqpar))
filepath_start = filepath_idxs[1] + 1
filepath_end = filepath_idxs[2] - 1
filepath_lines = mqpar[filepath_start:filepath_end]
filepaths_orig = gsub("<(\\/)?string>", "", filepath_lines) %>%
  trimws()
filenames = basename(filepaths_orig)
if (all(filenames == filepaths_orig)) 
  # Windows
  filenames %<>% gsub("^.*\\\\", "", .) 
## make sure there are no double-slashes!
filepaths = file.path(args$base_dir, filenames) %>%
  gsub("\\/\\/", "/", .)
# on Windows, change forward slashes to backwards ones
if (Sys.info()[['sysname']] == "Windows") {
  filepaths %<>% fix_windows_filepath()
}
mqpar[filepath_start:filepath_end] = paste0(
  "      ",
  "<string>",
  filepaths,
  "</string>")

# mqpar: change combined folder
# on Windows, change forward slashes to backwards ones
if (Sys.info()[['sysname']] == "Windows") {
  args$output_dir %<>% fix_windows_filepath()
}
# replace in a somewhat convoluted manner to avoid backslash gsub 
line = mqpar[grepl("fixedCombinedFolder", mqpar)]
line1 = gsub(">.*$", "", line)
line3 = gsub("^.*<", "", line)
line2 = paste0(">", args$output_dir, "<")
mqpar[grepl("fixedCombinedFolder", mqpar)] = paste0(line1, line2, line3)
## create directory, if it doesn't exist
if (!dir.exists(args$output_dir))
  dir.create(args$output_dir)

# # mqpar: change search folder
# mqpar[grepl("fixedSearchFolder", mqpar)] %<>% 
#   gsub(">.*<", paste0(">", args$search_dir, "<"), .)
# ## create directory, if it doesn't exist
# if (!dir.exists(args$search_dir))
#   dir.create(args$search_dir, recursive = T)
# 
# # mqpar: change temp folder
# mqpar[grepl("tempFolder", mqpar)] %<>% 
#   gsub(">.*<", paste0(">", args$tmp_dir, "<"), .)
# ## create directory, if it doesn't exist
# if (!dir.exists(args$tmp_dir))
#   dir.create(args$tmp_dir, recursive = T)

# mqpar: cleavage specificity
if (args$specificity == "specific") {
  # specific
  mqpar[grepl("maxMissedCleavages", mqpar)] %<>% 
    gsub(">.*<", paste0(">", 2, "<"), .)
  mqpar[grepl("enzymeMode", mqpar)] %<>% 
    gsub(">.*<", paste0(">", 0, "<"), .)
} else if (args$specificity == "semispecific") {
  # semispecific
  mqpar[grepl("maxMissedCleavages", mqpar)] %<>% 
    gsub(">.*<", paste0(">", 0, "<"), .)
  mqpar[grepl("enzymeMode", mqpar)] %<>% 
    gsub(">.*<", paste0(">", 1, "<"), .)
} else if (args$specificity == "semispecific_2") {
  # semispecific
  mqpar[grepl("maxMissedCleavages", mqpar)] %<>% 
    gsub(">.*<", paste0(">", 2, "<"), .)
  mqpar[grepl("enzymeMode", mqpar)] %<>% 
    gsub(">.*<", paste0(">", 1, "<"), .)
}


# mqpar: proteases
enzyme_idxs = which(grepl("<(\\/)?enzymes>", mqpar))
enzyme_start = enzyme_idxs[1] + 1
enzyme_end = enzyme_idxs[2] - 1
enzyme_lines = mqpar[enzyme_start:enzyme_end]
trypsin_str = enzyme_lines[grepl("Trypsin", enzyme_lines)][1]
if (args$lysc) {
  # add LysC cleavage
  lysc_str = gsub(">.*<", paste0(">", "LysC", "<"), trypsin_str)
  mqpar %<>% append(lysc_str, after = enzyme_end)
}
if (args$no_trypsin) {
  # remove trypsin lines
  remove = which(grepl("Trypsin", mqpar))
  if (length(remove) > 0)
    mqpar %<>% extract(-remove)
}

# mqpar: match between runs
if (args$no_mbr) {
  mqpar[grepl("matchBetweenRuns", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "False", "<"), .)
} else {
  mqpar[grepl("matchBetweenRuns", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "True", "<"), .)
}

# mqpar: second peptide search
if (args$no_second_peptide) {
  mqpar[grepl("secondPeptide", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "False", "<"), .)
} else {
  mqpar[grepl("secondPeptide", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "True", "<"), .)
}

# mqpar: LFQ normalization
if (args$disable_lfq_norm) {
  mqpar[grepl("lfqSkipNorm", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "True", "<"), .)
} else {
  mqpar[grepl("lfqSkipNorm", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "False", "<"), .)
}

# mqpar: MS/MS tolerance, in Da
if (!is.null(args$ms_ms_tol_da)) {
  message("setting MatchTolerance to ", args$ms_ms_tol_da, " Da")
  mqpar[grepl("MatchTolerance>", mqpar)] %<>% 
    gsub(">.*<", paste0(">", args$ms_ms_tol_da, "<"), .)
  mqpar[grepl("MatchToleranceInPpm>", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "False", "<"), .)
}
# mqpar: MS/MS tolerance, in ppm
if (!is.null(args$ms_ms_tol_ppm)) {
  message("setting MatchTolerance to ", args$ms_ms_tol_ppm, " ppm")
  mqpar[grepl("MatchTolerance>", mqpar)] %<>% 
    gsub(">.*<", paste0(">", args$ms_ms_tol_ppm, "<"), .)
  mqpar[grepl("MatchToleranceInPpm>", mqpar)] %<>% 
    gsub(">.*<", paste0(">", "True", "<"), .)
}

# mqpar: deamidation (NQ)
## PTMs used for protein ID
ptm_id_idxs = which(grepl("<(\\/)?variableModifications>", mqpar))
ptm_id_start = ptm_id_idxs[1] + 1
ptm_id_end = ptm_id_idxs[2] - 1
ptm_id_lines = mqpar[ptm_id_start:ptm_id_end]
## PTMs used for protein quantitation
ptm_quant_idxs = which(grepl("<(\\/)?restrictMods>", mqpar))
ptm_quant_start = ptm_quant_idxs[1] + 1
ptm_quant_end = ptm_quant_idxs[2] - 1
ptm_quant_lines = mqpar[ptm_quant_start:ptm_quant_end]
if (args$deamidation) {
  # insert into ID section
  ## (insert ID first to preserve ordering)
  deamidation_str =   "      <string>Deamidation (NQ)</string>"
  if (!any(grepl("Deamidation", ptm_id_lines)))
    mqpar %<>% append(deamidation_str, after = ptm_id_end)
  # insert into quant section
  if (!any(grepl("Deamidation", ptm_quant_lines)))
    mqpar %<>% append(deamidation_str, after = ptm_quant_end)
} else {
  # make sure there are none
  remove1 = which(grepl("Deamidation", ptm_id_lines)) + 
    ptm_id_start - 1
  remove2 = which(grepl("Deamidation", ptm_quant_lines)) + 
    ptm_quant_start - 1
  remove = c(remove1, remove2)
  if (length(remove) > 0)
    mqpar %<>% extract(-remove)
}

# mqpar: phosphorylation (STY)
## PTMs used for protein ID
ptm_id_idxs = which(grepl("<(\\/)?variableModifications>", mqpar))
ptm_id_start = ptm_id_idxs[1] + 1
ptm_id_end = ptm_id_idxs[2] - 1
ptm_id_lines = mqpar[ptm_id_start:ptm_id_end]
## PTMs used for protein quantitation
ptm_quant_idxs = which(grepl("<(\\/)?restrictMods>", mqpar))
ptm_quant_start = ptm_quant_idxs[1] + 1
ptm_quant_end = ptm_quant_idxs[2] - 1
ptm_quant_lines = mqpar[ptm_quant_start:ptm_quant_end]
if (args$phosphorylation) {
  # insert into ID section
  ## (insert ID first to preserve ordering)
  phosphorylation_str =   "      <string>Phospho (STY)</string>"
  if (!any(grepl("Phospho \\(STY\\)", ptm_id_lines)))
    mqpar %<>% append(phosphorylation_str, after = ptm_id_end)
  # insert into quant section
  if (!any(grepl("Phospho \\(STY\\)", ptm_quant_lines)))
    mqpar %<>% append(phosphorylation_str, after = ptm_quant_end)
} else {
  # make sure there are none
  remove1 = which(grepl("Phospho \\(STY\\)", ptm_id_lines)) + 
    ptm_id_start - 1
  remove2 = which(grepl("Phospho \\(STY\\)", ptm_quant_lines)) + 
    ptm_quant_start - 1
  remove = c(remove1, remove2)
  if (length(remove) > 0)
    mqpar %<>% extract(-remove)
}

# mqpar: carbamidomethylation, cysteine_NEM
# these modifications can be either fixed, variable, or neither
fixed_var_mods = c('carbamidomethylation', 'cysteine_nem')
fixed_var_mod_strs = c('Carbamidomethyl (C)', 'Cysteine NEM') %>%
  setNames(fixed_var_mods)
fixed_var_mod_patts = c('Carbamidomethyl \\(C\\)', 'Cysteine NEM') %>%
  setNames(fixed_var_mods)
for (fixed_var_mod in fixed_var_mods) {
  mod_patt = fixed_var_mod_patts[fixed_var_mod] %>% unname()
  mod_str = paste0("      <string>",
                   fixed_var_mod_strs[fixed_var_mod],
                   "</string>")
  
  var_mod_idxs = which(grepl("<(\\/)?variableModifications>", mqpar))
  var_mod_start = var_mod_idxs[1]
  var_mod_end = var_mod_idxs[2]
  var_mod_lines = mqpar[var_mod_start:var_mod_end]
  fixed_mod_idxs = which(grepl("<(\\/)?fixedModifications>", mqpar))
  fixed_mod_start = fixed_mod_idxs[1]
  fixed_mod_end = fixed_mod_idxs[2]
  fixed_mod_lines = mqpar[fixed_mod_start:fixed_mod_end]
  ## PTMs used for protein quantitation
  ptm_quant_idxs = which(grepl("<(\\/)?restrictMods>", mqpar))
  ptm_quant_start = ptm_quant_idxs[1] + 1
  ptm_quant_end = ptm_quant_idxs[2] - 1
  ptm_quant_lines = mqpar[ptm_quant_start:ptm_quant_end]
  
  if (args[[fixed_var_mod]] == "fixed") {
    # add to fixed modifications, if it isn't already
    if (!any(grepl(mod_patt, fixed_mod_lines)))
      mqpar %<>% append(mod_str, after = fixed_mod_end - 1)
    
    # remove from variable modifications, if it exists
    remove = which(grepl(mod_patt, var_mod_lines)) + 
      var_mod_start - 1
    if (length(remove) > 0)
      mqpar %<>% extract(-remove)
    
    # remove from modifications used for  quantification, if it exists
    remove = which(grepl(mod_patt, ptm_quant_lines)) + 
      ptm_quant_start - 1
    if (length(remove) > 0)
      mqpar %<>% extract(-remove)
  } else if (args[[fixed_var_mod]] == "variable") {
    # remove from fixed modifications, if it exists
    remove = which(grepl(mod_patt, fixed_mod_lines)) + 
      fixed_mod_start - 1
    if (length(remove) > 0)
      mqpar %<>% extract(-remove)
    
    # add to variable modifications, if it isn't already
    ## (do this one first, to preserve order)
    if (!any(grepl(mod_patt, var_mod_lines)))
      mqpar %<>% append(mod_str, after = var_mod_end - 1)
    
    # add to modifications used for quantification, if it isn't already
    if (!any(grepl(mod_patt, ptm_quant_lines)))
      mqpar %<>% append(mod_str, after = ptm_quant_end)
  } else if (args[[fixed_var_mod]] == "none") {
    # make sure there are none
    remove1 = which(grepl(mod_patt, fixed_mod_lines)) + 
      fixed_mod_start - 1
    remove2 = which(grepl(mod_patt, var_mod_lines)) + 
      var_mod_start - 1
    remove3 = which(grepl(mod_patt, ptm_quant_lines)) + 
      ptm_quant_start - 1
    remove = c(remove1, remove2, remove3)
    if (length(remove) > 0)
      mqpar %<>% extract(-remove)
  }
}

# mqpar: # of threads
mqpar[grepl("numThreads", mqpar)] %<>% 
  gsub(">.*<", paste0(">", args$n_threads, "<"), .)

# write mqpar file to 'generated' directory
mqpar_file = file.path(args$output_dir,
                       basename(args$mqpar_file))
mqpar_dir = dirname(mqpar_file)
if (!dir.exists(mqpar_dir))
  dir.create(mqpar_dir)
writeLines(mqpar, mqpar_file)

# start timer
start = Sys.time()

# run MaxQuant
if (Sys.info()[['sysname']] == "Windows") {
  cmd = paste(paste0(args$mq_dir, "/MaxQuantCmd.exe"), mqpar_file)
  message(cmd)
  system(cmd)
} else {
  cmd = paste("mono", paste0(args$mq_dir, "/MaxQuantCmd.exe"), mqpar_file)
  message(cmd)
  system(cmd)
}

# stop timer
stop = Sys.time()

# write elapsed time
elapsed = stop - start
time_file = file.path(args$output_dir, "elapsed_time.txt")
writeLines(as.character(elapsed), time_file)
