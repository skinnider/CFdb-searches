module unuse /arc/software/spack-2021/spack/share/spack/lmod/linux-centos7-x86_64/Core
module use /arc/software/spack-0.14.0-110/share/spack/lmod/linux-centos7-x86_64/Core

module load gcc/9.2.0 r/4.0.5-py3.7.6

cd ~/git/CFdb-searches
Rscript R/maxquant/PXD016521/write-mqpars.R \
  --raw_dir /scratch/st-ljfoster-1/CFdb/PXD016521 \
  --mqpar_file data/mqpar/PXD002322/mqpar-PXD002322-Hs_HCW_1.xml \
  --output_dir data/mqpar/PXD016521
