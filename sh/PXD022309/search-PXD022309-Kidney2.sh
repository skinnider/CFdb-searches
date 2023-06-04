~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD022309/mqpar-PXD022309-Kidney2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000000589-M.musculus.fasta.gz \
    --base_dir /mnt2/PXD022309 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt2/PXD022309/Kidney2 \
    --disable_lfq_norm TRUE \
    --lysc TRUE \
    --no_trypsin TRUE
