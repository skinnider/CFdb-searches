~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD017840/mqpar-PXD017840-Cox2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir /mnt/PXD017840 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD017840/Cox2-phosphorylation \
    --phosphorylation TRUE
