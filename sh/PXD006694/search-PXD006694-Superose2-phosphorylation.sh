# run on Windows in git bash
GIT_DIR=~/git/CFdb-searches
MNT_DIR=/d
cd $GIT_DIR
/c/Program\ Files/R/R-3.6.3/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ${GIT_DIR}/data/mqpar/PXD006694/mqpar-PXD006694-Superose2.xml \
    --fasta_file ${GIT_DIR}/data/fasta/filtered/UP000006548-A.thaliana.fasta.gz \
    --base_dir ${MNT_DIR}/PXD006694 \
    --mq_dir ~/Downloads/MaxQuant_1.6.5.0/MaxQuant/bin \
    --output_dir ${MNT_DIR}/PXD006694/Superose2-phosphorylation \
    --n_threads 30 \
    --phosphorylation TRUE
