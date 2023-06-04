~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD030050/mqpar-PXD030050-Ghosts_1percentDDM__IEX_3801.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir /mnt/PXD030050/Ghosts_1percentDDM__IEX_3801 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD030050/Ghosts_1percentDDM__IEX_3801-phosphorylation \
    --phosphorylation TRUE
