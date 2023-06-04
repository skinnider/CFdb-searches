~/R/R-3.6.0/bin/Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD016733/mqpar-PXD016733-Mic26_27.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir /mnt2/PXD016733 \
    --mq_dir ~/MaxQuant/bin \
    --output_dir /mnt2/PXD016733/Mic26_27-phosphorylation \
    --phosphorylation TRUE

