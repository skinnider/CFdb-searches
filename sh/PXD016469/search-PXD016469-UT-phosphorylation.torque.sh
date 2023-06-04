 #!/bin/bash
#PBS -l walltime=48:00:00,select=1:ncpus=16:mem=64gb
#PBS -N PXD016469-UT-phosphorylation-search
#PBS -o /scratch/st-ljfoster-1/logs/CFdb/PXD016469-UT-phosphorylation-search.out
#PBS -e /scratch/st-ljfoster-1/logs/CFdb/PXD016469-UT-phosphorylation-search.out

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/scratch/st-ljfoster-1/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/scratch/st-ljfoster-1/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/scratch/st-ljfoster-1/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/scratch/st-ljfoster-1/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

conda activate /scratch/st-ljfoster-1/CFdb/mq-env

cd ~/git/CFdb-searches

Rscript R/maxquant/run_maxquant.R \
    --mqpar_file ~/git/CFdb-searches/data/mqpar/PXD016469/mqpar-PXD016469-UT.xml \
    --fasta_file ~/git/CFdb-searches/data/fasta/filtered/UP000005640-H.sapiens.fasta.gz \
    --base_dir /scratch/st-ljfoster-1/CFdb/PXD016469 \
    --mq_dir /scratch/st-ljfoster-1/CFdb/MaxQuant/bin \
    --output_dir /scratch/st-ljfoster-1/CFdb/PXD016469/UT-phosphorylation \
    --phosphorylation
