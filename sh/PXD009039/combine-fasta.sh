# combine Plasmodium berghei and Mus musculus protein FASTA databases
cd ~/git/CFdb-searches/data/fasta/filtered
gzip -kd UP000000589-M.musculus.fasta.gz
gzip -kd UP000074855-P.berghei.fasta.gz
cat UP000074855-P.berghei.fasta UP000000589-M.musculus.fasta > UP000074855-UP000000589-P.berghei-M.musculus.fasta
gzip UP000074855-UP000000589-P.berghei-M.musculus.fasta
