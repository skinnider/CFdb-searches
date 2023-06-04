# run on Windows in git bash
GIT_DIR=~/git/CFdb-searches
MNT_DIR=/f
cd $GIT_DIR
/c/Program\ Files/R/R-3.6.2/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ${GIT_DIR}/data/mqpar/PXD011182/mqpar-PXD011182-expt_2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000001940-C.elegans.fasta.gz \
    --base_dir ${MNT_DIR}/PXD011182 \
    --mq_dir ~/Downloads/MaxQuant_1.6.5.0/MaxQuant/bin \
    --output_dir ${MNT_DIR}/PXD011182/expt_2

