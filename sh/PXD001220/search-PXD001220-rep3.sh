~/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD001220/mqpar-PXD001220-rep3.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir /mnt/PXD001220 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD001220/rep3 \
    --carbamidomethylation none
