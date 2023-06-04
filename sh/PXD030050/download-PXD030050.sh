cd /scratch/st-ljfoster-1/CFdb/PXD030050
wget -r --no-parent --no-verbose --no-clobber --continue -A "*.raw" ftp://massive.ucsd.edu/MSV000088471/raw

# move experiments out of parent directory
mv massive.ucsd.edu/MSV000088471/raw/* .
rm -r massive.ucsd.edu/MSV000088471/raw
