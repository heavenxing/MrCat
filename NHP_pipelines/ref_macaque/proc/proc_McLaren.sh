#!/usr/bin/env bash
set -e    # stop immediately on error

# code depends on FSL

# Extra info:
# The McLaren template comes with non-linear deformation parameters to warp to
# F99. These parameters are created using the old Normalise tool of SPM. They're
# no longer in use. I used world_bb.m to retrieve the bounding box of the
# McLaren image as used by SPM. For the original field-of-view this is [-66
# -41.5 -58; 61.5 86 61.5], for the restricted this is [-37.5 -34 -14; 37 60.5
# 45.5]. I used the SPM12 Deformations tool to convert the *_sn.mat parameters
# to a deformation field using a bounding box of [-37.5 -34 -14; 37 60.5 45.5]
# (so for the restricted field-of-view) and voxels [-0.5 0.5 0.5]. This created
# the image SL2F99_deform.nii. Then I used the SPM12 Normalise tool to warp the
# McLaren template to F99 using a bounding box of [-35.21 -55.833 -28.168;
# 36.216 37.725 30.683] and voxels [0.503 0.503 0.503]. This resulted in the
# image McLaren_F99.nii.gz. This images can be overlayed on the original F99
# template. Doing so reveals that the registration is pretty poor. I hope FNIRT
# will do a better job.

# retrieve the directory of this script
dirScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# define original, processing, and final reference data directories
dirOrig=$dirScript/../orig/McLaren
dirProc=$dirScript/McLaren
dirRef=$dirScript/../SL
mkdir -p $dirProc
mkdir -p $dirRef

# define a field-of-view
fov="49 150 15 190 88 120"

# copy original image and reduce the field-of-view
fslroi $dirOrig/112RM-SL_T1 $dirProc/McLaren $fov
fslmaths $dirProc/McLaren -thr 0 $dirProc/McLaren

# create a brain mask (throw out the 25% or 30% darkest voxels)
thr=$(fslstats $dirProc/McLaren -P 25)
fslmaths $dirProc/McLaren -thr $thr -bin $dirProc/McLaren_brain_mask
thr=$(fslstats $dirProc/McLaren -P 30)
fslmaths $dirProc/McLaren -thr $thr -bin $dirProc/McLaren_brain_mask_strict
thr=$(fslstats $dirProc/McLaren -P 35)
fslmaths $dirProc/McLaren -thr $thr -bin $dirProc/McLaren_brain_mask_verystrict

# copy (through fslroi and fslmaths to force correct fov + header)
# and rename all files to the final reference directory
# the main T1 image (same as in the proc dir)
fslroi $dirOrig/112RM-SL_T1 $dirRef/McLaren $fov
fslmaths $dirRef/McLaren -thr 0 $dirRef/McLaren
# the T2 image
fslroi $dirOrig/112RM-SL_T2 $dirRef/McLaren_T2 $fov
fslmaths $dirRef/McLaren_T2 -thr 0 $dirRef/McLaren_T2
# the CSF prior probability map
fslroi $dirOrig/csf_priors_ohsu+uw $dirRef/McLaren_CSF $fov
fslmaths $dirRef/McLaren_CSF -thr 0 $dirRef/McLaren_CSF
# the GM prior probability map
fslroi $dirOrig/gm_priors_ohsu+uw $dirRef/McLaren_GM $fov
fslmaths $dirRef/McLaren_GM -thr 0 $dirRef/McLaren_GM
# the WM prior probability map
fslroi $dirOrig/wm_priors_ohsu+uw $dirRef/McLaren_WM $fov
fslmaths $dirRef/McLaren_WM -thr 0 $dirRef/McLaren_WM
# and the masks
imcp $dirProc/McLaren_brain_mask $dirRef/McLaren_brain_mask
imcp $dirProc/McLaren_brain_mask_strict $dirRef/McLaren_brain_mask_strict
