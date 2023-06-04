# run on Windows in git bash
GIT_DIR=~/git/CFdb-searches
MNT_DIR=/f
cd $GIT_DIR
/c/Program\ Files/R/R-3.6.3/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ${GIT_DIR}/data/mqpar/PXD013809/mqpar-PXD013809-rep4.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir ${MNT_DIR}/PXD013809 \
    --mq_dir ~/Downloads/MaxQuant_1.6.5.0/MaxQuant/bin \
    --output_dir ${MNT_DIR}/PXD013809/rep4-phosphorylation \
    --disable_lfq_norm TRUE \
    --n_threads 30 \
    --phosphorylation TRUE

