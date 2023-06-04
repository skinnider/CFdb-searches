~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD007288/mqpar-PXD007288-Lung1.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000000589-M.musculus.fasta.gz \
    --base_dir /mnt/PXD007288 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD007288/Lung1-phosphorylation \
    --disable_lfq_norm TRUE \
    --lysc TRUE \
    --no_trypsin TRUE \
    --phosphorylation TRUE