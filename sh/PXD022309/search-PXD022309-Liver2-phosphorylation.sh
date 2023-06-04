# run on Windows in git bash
GIT_DIR=~/git/CFdb-searches
MNT_DIR=/f
cd $GIT_DIR
/c/Program\ Files/R/R-3.6.3/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ${GIT_DIR}/data/mqpar/PXD022309/mqpar-PXD022309-Liver2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000000589-M.musculus.fasta.gz \
    --base_dir ${MNT_DIR}/PXD022309 \
    --mq_dir ~/Downloads/MaxQuant_1.6.5.0/MaxQuant/bin \
    --output_dir ${MNT_DIR}/PXD022309/Liver2-phosphorylation \
    --disable_lfq_norm TRUE \
    --no_trypsin TRUE \
    --lysc TRUE \
    --n_threads 30 \
    --phosphorylation TRUE

