~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD022357/mqpar-PXD022357-SB1.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000059680-O.sativa.fasta.gz \
    --base_dir /mnt/PXD022357 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD022357/SB1-phosphorylation \
    --phosphorylation TRUE
