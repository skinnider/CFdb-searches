# list SEC files from the control and ATP replicates
cd ~/projects/rrg-ljfoster-ab/skinnim/CFdb/PXD006543
grep 'File Name' SEC_ATP.pep.xml > ATP_files.txt
grep 'File Name' SEC_Vehicle.pep.pep.xml > Vehicle_files.txt
