#!/bin/bash

dataroot=/mounts/data/preprocessed/modalities/dti/Strk/dti
export initroot=$dataroot/CHTC2

parallel -j1 ./DWICorrect_AddJobToDAG.sh ::: $dataroot/*V1_nozfi.mif > DWICorrect_March302019_V2.dag
