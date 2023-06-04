# run on Windows in git bash
GIT_DIR=~/git/CFdb-searches
MNT_DIR=/f
cd $GIT_DIR
/c/Program\ Files/R/R-3.6.3/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ${GIT_DIR}/data/mqpar/PXD006543/mqpar-PXD006543-Vehicle.xml \
    --fasta_file ${GIT_DIR}/data/fasta/filtered/UP000000625-E.coli.fasta.gz \
    --base_dir ${MNT_DIR}/PXD006543/ \
    --mq_dir ~/Downloads/MaxQuant_1.6.5.0/MaxQuant/bin \
    --output_dir ${MNT_DIR}/PXD006543/Vehicle-phosphorylation \
    --n_threads 26 \
    --phosphorylation
