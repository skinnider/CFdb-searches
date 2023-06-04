## MaxQuant

This directory contains R code used to create mqpar files and search CF-MS raw data files against a protein FASTA database using MaxQuant. 

Note, however, that the mqpar files written by the scripts within these subdirectories are _not_ the final mqpar files used to search the CF-MS data. Briefly the workflow used to re-analyze the data was as follows:

First, an initial mqpar file was created for each experiment, by modifying a 'base' mqpar file containing the default parameters for MaxQuant version 1.6.5.0. This 'base' mqpar file delineates the design of the experiment, including includes the filenames of the raw data files, each of which are linked to their experiment and fraction (in MaxQuant terminology). This initial file also contains any information about metabolic or chemical labelling, where appropriate. 

This initial mqpar file was then further modified when running the `run_maxquant.R` script, which specifies the protein FASTA database, the location of the raw files, any protein modifications, and other settings as described in the CLI of `run_maxquant.R`. The precise settings used to run this R script are provided in the `sh` directory. 