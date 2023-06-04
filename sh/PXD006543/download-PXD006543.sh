cd /home/skinnim/projects/rrg-ljfoster-ab/skinnim/CFdb/PXD006543
wget -r -l2 --no-parent --no-directories --no-verbose --no-clobber --continue -A "*.raw" ftp://ftp.pride.ebi.ac.uk/pride/data/archive/2018/01/PXD006543

# get XML files to obtain lists of files
wget ftp://ftp.pride.ebi.ac.uk/pride/data/archive/2018/01/PXD006543/SEC_ATP.pep.xml
wget ftp://ftp.pride.ebi.ac.uk/pride/data/archive/2018/01/PXD006543/SEC_Vehicle.pep.pep.xml

