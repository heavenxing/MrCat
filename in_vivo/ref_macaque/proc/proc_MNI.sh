#!/usr/bin/env bash
#set -e    # don't stop immediately on error as wm_import will return one

# dependent on having FSl and workbench installed, including wb_import and wb_command

# retrieve the directory of this script
dirScript=$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )


# ------------------------------ #
# section 1: copy and correct the original template
# ------------------------------ #

# define original and target data directories, for mulatta and the mixed
dirOrigMul=$dirScript/../orig/MNI/mulatta
dirOrigMix=$dirScript/../orig/MNI/mix
dirProcMul=$dirScript/MNI/mulatta
dirProcMix=$dirScript/MNI/mix
dirRef=$dirScript/../MNI
mkdir -p $dirProcMul
mkdir -p $dirProcMix
mkdir -p $dirRef


# first the mulatta
# copy the original, to avoid extension clashes
cp $dirOrigMul/rhesus_7_model-MNI.nii.gz $dirProcMul/rhesus_7_model-MNI.nii.gz

# correct the image based on the linear registration
sh $dirScript/corr_MNI.sh \
  --workingdir=$dirProcMul/lin \
  --scriptdir=$dirScript \
  --orig=$dirProcMul/rhesus_7_model-MNI \
  --basename="MNI" \
  --lin

# and now run the mulatta/fascularis mix
# copy the original, to avoid extension clashes
cp $dirOrigMix/macaque_25_model-MNI.nii.gz $dirProcMix/macaque_25_model-MNI.nii.gz

# correct the image based on the linear registration
sh $dirScript/corr_MNI.sh \
  --workingdir=$dirProcMix/lin \
  --scriptdir=$dirScript \
  --orig=$dirProcMix/macaque_25_model-MNI \
  --basename="MNI" \
  --lin

# ------------------------------ #
# section 2: copy and rename files
# ------------------------------ #

# move them to the appropriate space folder
imcp $dirProcMul/lin/MNI_corr $dirRef/MNI
imcp $dirProcMul/lin/MNI_brain_mask $dirRef/MNI_brain_mask
imcp $dirProcMul/lin/MNI_brain_mask_strict $dirRef/MNI_brain_mask_strict
imcp $dirProcMul/lin/MNI_corr_05mm $dirRef/MNI_05mm
imcp $dirProcMul/lin/MNI_brain_mask_05mm $dirRef/MNI_brain_mask_05mm
imcp $dirProcMul/lin/MNI_brain_mask_strict_05mm $dirRef/MNI_brain_mask_strict_05mm


# The code below runs the same corr_MNI script, but now with non-linear
# registration. This takes ages, because of the fanatic fnirt configuration and
# because the data has a resolution of 0.25mm isotropic. I would not recommend
# running this nonlin code, simple because the time it takes makes it
# inpractical. I have run it once, and included the results in the folder
# "nonlin". Hopefully that will be it.
<<"COMMENT_BLOCK"

# first the mulatta
# correct the image based on the linear registration
sh $dirScript/corr_MNI.sh \
  --workingdir=$dirProcMul/nonlin \
  --scriptdir=$dirScript \
  --orig=$dirProcMul/rhesus_7_model-MNI \
  --basename="MNI" \
  --config=fnirt_1mm.cnf \
  --nonlin

# and now run the mulatta/fascularis mix
# correct the image based on the linear registration
sh $dirScript/corr_MNI.sh \
  --workingdir=$dirProcMix/nonlin \
  --scriptdir=$dirScript \
  --orig=$dirProcMix/macaque_25_model-MNI \
  --basename="MNI" \
  --config=fnirt_1mm.cnf \
  --nonlin

COMMENT_BLOCK
