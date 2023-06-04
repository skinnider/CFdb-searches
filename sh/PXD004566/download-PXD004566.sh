cd /scratch/st-ljfoster-1/CFdb/PXD004566
wget -r -l2 --no-parent --no-directories --no-verbose --no-clobber --continue -A "*zip" ftp://ftp.pride.ebi.ac.uk/pride/data/archive/2019/10/PXD004566/

unzip BN3to12_RAW.zip
unzip BN4to16_RAW.zip

mkdir BN3to12_MaxQuant_txt
mv BN3to12_MaxQuant_txt.zip BN3to12_MaxQuant_txt
cd BN3to12_MaxQuant_txt 
unzip BN3to12_MaxQuant_txt.zip

cd ..

mkdir BN4to16_MaxQuant_txt
mv BN4to16_MaxQuant_txt.zip BN4to16_MaxQuant_txt
cd BN4to16_MaxQuant_txt 
unzip BN4to16_MaxQuant_txt.zip

