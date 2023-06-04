~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD021454/mqpar-PXD021454-B2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000189702-G.hirsutum.fasta.gz \
    --base_dir /mnt/PXD021454 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt/PXD021454/B2-phosphorylation \
    --phosphorylation TRUE
