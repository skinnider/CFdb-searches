~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD021451/mqpar-PXD021451-B1.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000189702-G.hirsutum.fasta.gz \
    --base_dir /mnt2/PXD021451 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt2/PXD021451/B1-phosphorylation \
    --phosphorylation TRUE
