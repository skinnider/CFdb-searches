~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD025478/mqpar-PXD025478-WT.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000000589-M.musculus.fasta.gz \
    --base_dir /mnt/PXD025478 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD025478/WT-phosphorylation \
    --phosphorylation TRUE
