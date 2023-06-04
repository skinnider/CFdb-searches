~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD030050/mqpar-PXD030050-Ghosts_DDM_BiobasicSEC-2.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir /mnt2/PXD030050/Ghosts_DDM_BiobasicSEC-2 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt2/PXD030050/Ghosts_DDM_BiobasicSEC-2-phosphorylation \
    --phosphorylation TRUE
