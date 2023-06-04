~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD017463/mqpar-PXD017463-KO2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000000589-M.musculus.fasta.gz \
    --base_dir /mnt/PXD017463 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD017463/KO2-phosphorylation \
    --phosphorylation TRUE \
    --disable_lfq_norm TRUE
