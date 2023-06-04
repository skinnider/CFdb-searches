setwd("~/git/CFdb-searches")
options(stringsAsFactors = F)
library(tidyverse)
library(magrittr)
library(rvest)

# read html
html = read_html("data/mqpar//IPX0001620001/iProX - integrated Proteome resources.html")
# extract file names
filenames = html %>% html_nodes('td span.aspera') %>% html_text()
# remove AP-MS
raw_files = filenames %>% 
  extract(grepl('\\.raw$', .)) %>% 
  extract(!grepl('Sll', .))
# add links
links = paste0('https://download.iprox.cn/IPX0001620000/IPX0001620001/', raw_files)

# now, write download script
lines = paste0(
  'wget --no-parent --no-directories --no-verbose --no-clobber --continue "', 
  links, '"')
lines %<>% c('cd /scratch/st-ljfoster-1/CFdb/IPX0001620001', .)
writeLines(lines, "sh/IPX0001620001/download-IPX0001620001.sh")
