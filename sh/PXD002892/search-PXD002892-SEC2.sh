~/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD002892/mqpar-PXD002892-SEC2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir /mnt/sdc1/PXD002892 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/sdc1/PXD002892/SEC2 \
    --disable_lfq_norm
