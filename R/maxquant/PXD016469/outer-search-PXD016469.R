setwd("~/git/CFdb-searches")
options(stringsAsFactors = FALSE)
library(argparse)

# parse arguments
parser = ArgumentParser(prog = 'outer-search-PXD016469.R')
parser$add_argument('--allocation', type = 'character', default = "root")
args = parser$parse_args()

library(tidyverse)
library(magrittr)

# load grid functions
source("R/functions/submit_job.R")
source("R/functions/write_sh.R")
source("R/functions/detect_system.R")

# create grid
grid = tidyr::crossing(
  replicate = c('UT', 'LPS'),
  phosphorylation = c(TRUE, FALSE)
)

# set up mqpar files
mqpar_files = paste0("~/git/CFdb-searches/data/mqpar/PXD016469/mqpar-PXD016469-", 
                     grid$replicate, ".xml")

# check output files
output_dirs = pmap_chr(grid, function(...) {
  current = tibble(...)
  output_dirname = ifelse(current$phosphorylation, 
                          paste0(current$replicate, '-phosphorylation'),
                          current$replicate)
  file.path(base_dir, 'PXD016469', output_dirname)
})
output_files = file.path(output_dirs, 'combined/txt/proteinGroups.txt')

# subset grid
grid0 = grid %>% 
  mutate(mqpar_file = mqpar_files,
         output_dir = output_dirs,
         output_file = output_files) %>% 
  filter(!file.exists(output_file)) %>% 
  mutate(mq_dir = file.path(base_dir, 'MaxQuant/bin'),
         base_dir = file.path(base_dir, 'PXD016469'),
         fasta_file = '~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz'
  ) %>% 
  dplyr::select(mqpar_file, fasta_file, base_dir, mq_dir, output_dir, 
                phosphorylation)

# write
grid_file = "sh/grids/search-PXD016469.txt"
grid_dir = dirname(grid_file)
if (!dir.exists(grid_dir))
  dir.create(grid_dir, recursive = TRUE)
write.table(grid0, grid_file, quote = FALSE, row.names = FALSE, sep = "\t")

# write the sh file dynamically
sh_file = 'sh/maxquant/search-PXD016469.sh'
write_sh(job_name = 'search-PXD016469',
         sh_file = sh_file,
         grid_file = grid_file,
         inner_file = 'R/maxquant/run_maxquant.R',
         system = system,
         time = 24,
         cpus = 16,
         mem = 64)

# finally, run the job on whatever system we're on
submit_job(grid0, sh_file, args$allocation, system)
