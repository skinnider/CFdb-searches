# run on Windows in git bash
GIT_DIR=~/git/CFdb-searches
MNT_DIR=/f
cd $GIT_DIR
/c/Program\ Files/R/R-3.6.3/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ${GIT_DIR}/data/mqpar/PXD021452/mqpar-PXD021452-Bio2.xml \
    --fasta_file ${GIT_DIR}/data/fasta/filtered/UP000008827-G.max.fasta.gz \
    --base_dir ${MNT_DIR}/PXD021452 \
    --mq_dir ~/Downloads/MaxQuant_1.6.5.0/MaxQuant/bin \
    --output_dir ${MNT_DIR}/PXD021452/Bio2-phosphorylation \
    --phosphorylation TRUE \
    --n_threads 28
