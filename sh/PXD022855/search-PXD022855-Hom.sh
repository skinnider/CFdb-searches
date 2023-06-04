~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD022855/mqpar-PXD022855-Hom.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000000589-M.musculus.fasta.gz \
    --base_dir /mnt/PXD022855 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD022855/Hom-phosphorylation \
    --phosphorylation TRUE
