#!/bin/bash
# 05/20/2021
cd /mnt/vpgroup/Data/fMRI_Studies/K/SCANS/RAW
ls KS*/MR/*/* -d | parallel --bar --rpl '{p} s:/:_:g' dcm2niix -o nifti -f {p}_suffix_%f_%d_%v_%s_%z {}
# 165, 2068

cd /mnt/vpgroup/Data/fMRI_Studies/CoulterStrokeRehab/Scans/Raw
find . -type d -exec sh -c '(ls -p "{}"|grep />/dev/null)||echo "{}"' \; | parallel --progress --rpl '{p} s:./::;s:/:_:g' dcm2niix -o /mnt/vpgroup/csrnifti -f {p}_suffix_%f_%d_%v_%s_%z {}
# 255,

cd /mnt/vpgroup/Data/fMRI_Studies/StrokePlasticity
find . -type d -exec sh -c '(ls -p "{}"|grep />/dev/null)||echo "{}"' \; | parallel --dry-run --rpl '{p} s:./::;s:/:_:g' dcm2niix -o /mnt/vpgroup/spnifti -f {p}_suffix_%f_%d_%v_%s_%z {}
# 241, 

cd /mnt/vpgroup/Data/fMRI_Studies/RO1_stroke/Scans/Raw
find . -type d -exec sh -c '(ls -p "{}"|grep />/dev/null)||echo "{}"' \; | parallel --dry-run --rpl '{p} s:./::;s:/:_:g' dcm2niix -o /mnt/vpgroup/r01strokenifti -f {p}_suffix_%f_%d_%v_%s_%z {}

# 05/21/2021
cd /mnt/vpgroup/shapiro
ls knifti/*.nii | grep -iE "dti|noddi"
ls *nifti/*.bvec | parallel --dry-run 'mrconvert {.}.nii -fslgrad {} {.}.bval - | dwidenoise - - | mrdegibbs - - | dwi2tensor - - | tensor2metric - -adc {.}_adc.nii.gz -mask $(mrconvert {.}.nii -fslgrad {} {.}.bval - | dwi2mask - -) -force'

# 05/22/2021 (may be try to generate these on isleta or inca)
cd /mnt/vpgroup/shapiro
ls *nifti/*.bvec | parallel -j1 --bar cp {.}.nii {} {.}.bval ./dwiniftis/

# Ran the jobs on four different servers.
# 247 (csr), 232 (sp), k (202), r01 (8). Total of 689 DWI. ETA for adc maps is Monday (5/24/2021) morning based on parallel --bar estimates. r01 is already done.

# 05/26/2021 bzero mean
# imagerecon-1
ls csrnifti/*.bvec | parallel --bar -j1 'dwiextract {.}.nii -fslgrad {} {.}.bval -bzero - | mrmath - mean {.}_bzeromean.nii.gz -axis 3'
# imagerecon-2
ls spnifti/*.bvec | parallel --bar -j1 'dwiextract {.}.nii -fslgrad {} {.}.bval -bzero - | mrmath - mean {.}_bzeromean.nii.gz -axis 3'
# imagerecon-3
ls knifti/*.bvec | parallel --bar -j1 'dwiextract {.}.nii -fslgrad {} {.}.bval -bzero - | mrmath - mean {.}_bzeromean.nii.gz -axis 3'
# r-vpgroup1 (done)
ls r01strokenifti/*.bvec | parallel --bar -j1 'dwiextract {.}.nii -fslgrad {} {.}.bval -bzero - | mrmath - mean {.}_bzeromean.nii.gz -axis 3'

cd /mnt/vpgroup/shapiro
ls jiminputs/* -d | parallel --bar mkdir -p {1}/{2} :::: - ::: flair dwi bravo
ls csrnifti/*.nii | grep -i "flair" | parallel --bar -j1 cp {} jiminputs/csr/flair/
ls csrnifti/*.nii | grep -i "brav" | parallel --bar -j1 cp {} jiminputs/csr/bravo/

ls knifti/*.nii | grep -i "flair" | parallel --bar -j1 cp {} jiminputs/k/flair/
ls knifti/*.nii | grep -i "brav" | parallel --bar -j1 cp {} jiminputs/k/bravo/

ls spnifti/*.nii | grep -i "flair" | parallel --bar -j1 cp {} jiminputs/sp/flair/
ls r01strokenifti/*.nii | grep -i "brav" | parallel --bar -j1 cp {} jiminputs/r01/bravo/

ls r01strokenifti/*.nii | grep -i "flair" | parallel --bar -j1 cp {} jiminputs/r01/flair/
ls r01strokenifti/*.nii | grep -i "brav" | parallel --bar -j1 cp {} jiminputs/r01/bravo/

# 05/27/2021
cd /mnt/vpgroup/shapiro
parallel -j1 'echo $(ls jiminputs/{1}/bravo/* | wc -l) $(ls {2}/*.nii | grep -i "bravo" | wc -l) $(ls {2}/*.nii | grep -i "flair" | wc -l) $(ls jiminputs/{1}/flair/* | wc -l) $(ls {2}/*.bvec | wc -l) $(ls jiminputs/{1}/dwi/* | wc -l)' ::: csr k sp r01 :::+ csrnifti knifti spnifti r01strokenifti

# 05/31/2021
cd /mnt/vpgroup/shapiro/jiminputs
ls csr/dwi/*adc* | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csr_dwi_adc.csv
ls csr/dwi/*bzero* | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csr_dwi_b0.csv
ls csr/flair/ | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csr_flair.csv
ls csr/bravo/ | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csr_bravo.csv

ls k/dwi/*adc* | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/k_dwi_adc.csv
ls k/dwi/*bzero* | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/k_dwi_b0.csv
ls k/flair | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/k_flair.csv
ls k/bravo | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/k_bravo.csv

ls sp/dwi/*adc* | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/sp_dwi_adc.csv
ls sp/dwi/*bzero* | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/sp_dwi_b0.csv
ls sp/flair | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/sp_flair.csv
ls sp/bravo | sed -n 's:.*/::;s:\(.*V[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/sp_bravo.csv

ls r01/dwi/*adc* | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:'  > csvs/r01_dwi_adc.csv
ls r01/dwi/*bzero* | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:'  > csvs/r01_dwi_b0.csv
ls r01/flair | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/r01_flair.csv
ls r01/bravo | sed -n 's:.*/::;s:\(.*M[0-9]\)\(.*\):\1,\1\2:p' | sed '1s:^:id,filename\n:' > csvs/r01_bravo.csv

# 06/07/2021
cd /home/adluru/StrokeAndDiffusionProject/uwstrokeproject/shapiro/csvs
ls *.csv | sed 's:*::' | parallel --rpl '{m} s:.*_::;s:.csv::' --bar 'sed -i "s:filename:{m}:" {}'

# 06/08/2021
parallel --bar -I : 'cat /mnt/vpgroup/shapiro/jiminputs/csvs/:_joined.csv | parallel -I {} --header : --colsep "," -d "\r\n" bash /home/nxa008/jmecp/coregisterforjim.sh /mnt/vpgroup/shapiro/jiminputs/:/bravo/{5} /mnt/vpgroup/shapiro/jiminputs/:/flair/{4} /mnt/vpgroup/shapiro/jiminputs/:/dwi/{3} /mnt/vpgroup/shapiro/jiminputs/:/dwi/{2}' ::: csr k sp r01

# 06/09/2021 b>0 max and average
# DGX
ls csrnifti/*.bvec spnifti/*.bvec knifti/*.bvec r01strokenifti/*.bvec | parallel --bar -j1 'dwiextract {.}.nii -fslgrad {} {.}.bval -no_bzero - | mrmath - mean {.}_bgtzero_mean.nii.gz -axis 3 -force'
ls csrnifti/*.bvec spnifti/*.bvec knifti/*.bvec r01strokenifti/*.bvec | parallel --dry-run 'dwiextract {.}.nii -fslgrad {} {.}.bval -no_bzero - | mrmath - max {.}_bgtzero_max.nii.gz -axis 3'
