#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# steps to create a ex-vivo T1w template
# 1 - manually adjust the contrast of the McLaren T1w template (F99 space) to
#     roughly match umberto's ex-vivo T1w contrast
# 2 - linear and non-linear register umberto (source) to this template (ref)
# 3 - compare the voxel intensities of the source and original ref to describe a
#     polynomial relationship between the two (in matlab). Re-colour the orignal
#     ref according to this relationship (in matlab) and adjust slightly (in sh).
# 4 - repeat steps 2 and 3 to optimise.

# ------------------------------ #
# usage
# ------------------------------ #

usage() {
cat <<EOF

This script creates a ex-vivo T1w template in the following steps:
1 - adjust the contrast of the McLaren T1w template (F99 space) to roughly match
    umberto's ex-vivo T1w contrast, using pre-selected initial conversion
2 - linear and non-linear register umberto (source) to this template (ref)
3 - compare the voxel intensities of the source and original ref and fit
    multiple smoothing splines (or a cubic polynomial function) to capture the
    relationship between the two (in matlab). Re-colour the orignal ref
    according to this relationship (in matlab) and adjust slightly (in sh)
4 - repeat steps 2 and 3 to optimise, and then 2 to display the final result

example:
      $(basename $0) --subjlist="oddie@hilary@umberto" --flgfit=poly

usage: $(basename $0)
      [--subjlist=<list of subjects>] (default: oddie@hilary@umberto)
      [--flgfit=<spline / poly>] function to fit image types (default: spline)

EOF
}


# ------------------------------ #
# overhead
# ------------------------------ #

# if help is requested, return the usage
if [[ $@ =~ --help ]] ; then usage; exit 0; fi

# give error if this script is run on the general server
[[ $(hostname -s) == jalapeno ]] && >&2 echo "matlab cannot be run on the main server, please use \"fsl_sub\" or \"qlogin -q interactive.q\"" && exit 1

# define reference
RD=$MRCATDIR/ref_macaque/F99
ref=$RD/McLaren

# set defaults
subjList="umberto hilary oddie"
flgFit="spline" # poly / spline

# parse the input arguments
for a in "$@" ; do
  case $a in
    -s=*|--subj=*|--subjlist=*) subjList="${a#*=}"; shift ;;
    -f=*|--fit=*|--flgfit=*)    flgFit="${a#*=}"; shift ;;
  esac
done
subjList="${subjList//@/ }"


# loop over monkeys
for monkey in $subjList ; do

  # define input image
  WD=$MRCATDIR/ref_macaque/proc/ex_vivo_template/$monkey
  img=$WD/T1w_restore
  brainmask=$WD/brainmask
  config=$MRCATDIR/HCP_scripts/fnirt_1mm.cnf


  # ----------------------------------------------------------------------- #
  # STEP 1: create a 'visual' match between the ref and the source contrast
  # ----------------------------------------------------------------------- #

  # create a smooth weighting mask
  fslmaths ${ref}_brain_mask_strict -s 0.5 $WD/McLaren_weighting

  # get image statistics
  maxRef=$(fslstats $ref -R | awk '{print $2}')
  meanRef=$(fslstats $ref -k ${ref}_brain_mask_strict -M)
  stdRef=$(fslstats $ref -k ${ref}_brain_mask_strict -S)
  meanImg=$(fslstats $img -k $brainmask -M)
  stdImg=$(fslstats $img -k $brainmask -S)

  # scale reference image to standard units, invert, and log transform
  fslmaths $ref -sub $meanRef -mul $WD/McLaren_weighting -div $stdRef -mul -1 -add 2 -thr 0 -add 1 -log $WD/McLaren_inv_manual
  # scale by source image units
  meanInv=$(fslstats $WD/McLaren_inv_manual -k ${ref}_brain_mask_strict -M)
  stdInv=$(fslstats $WD/McLaren_inv_manual -k ${ref}_brain_mask_strict -S)
  fslmaths $WD/McLaren_inv_manual -sub $meanInv -div $stdInv -mul $stdImg -add $meanImg -mul $WD/McLaren_weighting $WD/McLaren_inv_manual


  # ----------------------------------------------------------- #
  # STEP 2: register the source to the newly coloured reference
  # ----------------------------------------------------------- #

  # linear registration of the source image to the (inverted) reference
  flirt -dof 12 -ref $WD/McLaren_inv_manual -refweight ${ref}_brain_mask -in $img -inweight $brainmask -omat $WD/source_to_refinv.mat
  flirt -dof 12 -ref $ref -refweight ${ref}_brain_mask -in $img -inweight $brainmask -omat $WD/source_to_ref.mat

  # compare the costs (inverse against the regular reference)
  costinv=$(flirt -ref $ref -in $img -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/source_to_refinv.mat | head -1 | cut -d' ' -f1)
  costref=$(flirt -ref $ref -in $img -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/source_to_ref.mat | head -1 | cut -d' ' -f1)
  [[ $(echo $costref $costinv | awk '($1<$2){print "1"}') == 1 ]] && translin=$WD/source_to_ref.mat || translin=$WD/source_to_refinv.mat

  # spline interpolate according to the best registration
  applywarp --rel --interp=spline -i $img -r $ref --premat=$translin -o $WD/T1w_restore_F99lin
  fslmaths $WD/T1w_restore_F99lin -thr 0 $WD/T1w_restore_F99lin

  # non-linear registration to the inverted reference
  fnirt --ref=$WD/McLaren_inv_manual --refmask=${ref}_brain_mask --in=$img --intin=$WD/T1w_restore_F99lin --aff=$translin --fout=$WD/source_to_refinv_warp --config=$config

  # resample the source image and mask to the reference space
  applywarp --rel --interp=nn -i $brainmask -r $ref -w $WD/source_to_refinv_warp -o $WD/brainmask_F99
  applywarp --rel --interp=spline -i $img -r $ref -w $WD/source_to_refinv_warp -o $WD/T1w_restore_F99
  fslmaths $WD/T1w_restore_F99 -thr 0 $WD/T1w_restore_F99


  # -------------------------------------------------------------- #
  # STEP 3: use the matlab script compare_source_ref_intensities.m
  # -------------------------------------------------------------- #

  if [[ $OSTYPE == "darwin"* ]] ; then # when running on OS X
    # get all matlab versions in /Applications
    matlabdir=($(echo /Applications/MATLAB_R20*))
    # retrieve only the latest version
    matlabdir=${matlabdir[${#matlabdir[@]}-1]}
    # and retrieve the binaries
    matlabbin=$matlabdir/bin
  elif [[ $OSTYPE == "linux-gnu" ]] ; then # when running on Linux
    #matlabbin=/opt/fmrib/bin/
    matlabbin=/opt/fmrib/MATLAB/R2015b/bin
  fi
  rootDir=$MRCATDIR/ref_macaque
  # fit splines (or polynomial) to describe relationship between the two contrasts
  $matlabbin/matlab -nojvm -nodisplay -nosplash -r "try; cd $rootDir/proc/ex_vivo_template; fit_voxel_intensities('$WD','$rootDir','$flgFit'); catch ME; disp('ai, something went wrong.'); rethrow(ME); end; quit"

  # STEP 3: continue after the matlab script is finished

  # option 1: use the matlab output
  #fslmaths $WD/McLaren_inv_fit -thr 0 $WD/McLaren_inv

  # option 2: use the brain edge from the original reference image
  #fslmaths ${ref} -thr 160 -bin -s 0.5 $WD/McLaren_weighting
  #fslmaths $WD/McLaren_inv -mul $WD/McLaren_weighting $WD/McLaren_inv
  #fslmaths $WD/McLaren_weighting -mul -1 -add 1 -mul ${ref} -add $WD/McLaren_inv -thr 0 $WD/McLaren_inv

  # option 3: make the brain edge brighter (to force slight expansion)
  # threshold the fitted template
  fslmaths $WD/McLaren_inv_fit -thr 0 $WD/McLaren_inv
  # create a strict, but smooth, weighting mask
  fslmaths ${ref} -thr 160 -bin -s 0.5 -mul -1 -add 2 $WD/McLaren_weighting
  # everything inside the weighting mask is taken from the fitted template
  # and everything outside is taken from the orignal template
  fslmaths $WD/McLaren_inv -mul $WD/McLaren_weighting -thr 0 $WD/McLaren_inv
  # dilate the edge, just to make it a bit brighter
  fslmaths $WD/McLaren_inv_fit -thr 0 -dilF -min $WD/McLaren_inv $WD/McLaren_inv
  # and smoothly threshold to force zeros outside the brain
  fslmaths $WD/McLaren_inv -thr 10 -bin -s 0.5 $WD/McLaren_weighting
  fslmaths $WD/McLaren_inv -mul $WD/McLaren_weighting $WD/McLaren_inv


  # --------------------------------------------------------------- #
  # STEP 4: linear and non-linear registration to this new template
  # --------------------------------------------------------------- #

  # linear registration of the source image to the (inverted) reference
  flirt -dof 12 -ref $WD/McLaren_inv -refweight ${ref}_brain_mask -in $img -inweight $brainmask -omat $WD/source_to_refinv.mat

  # compare the cost against the regular reference
  costinv=$(flirt -ref $ref -in $img -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/source_to_refinv.mat | head -1 | cut -d' ' -f1)
  [[ $(echo $costref $costinv | awk '($1<$2){print "1"}') == 1 ]] && translin=$WD/source_to_ref.mat || translin=$WD/source_to_refinv.mat

  # spline interpolate according to the best registration
  applywarp --rel --interp=spline -i $img -r $ref --premat=$translin -o $WD/T1w_restore_F99lin
  fslmaths $WD/T1w_restore_F99lin -thr 0 $WD/T1w_restore_F99lin

  # non-linear registration to the inverted reference
  fnirt --ref=$WD/McLaren_inv --refmask=${ref}_brain_mask --in=$img --intin=$WD/T1w_restore_F99lin --aff=$translin --fout=$WD/source_to_refinv_warp --config=$config

  # resample the source image and mask to the reference space
  applywarp --rel --interp=nn -i $brainmask -r $ref -w $WD/source_to_refinv_warp -o $WD/brainmask_F99
  applywarp --rel --interp=spline -i $img -r $ref -w $WD/source_to_refinv_warp -o $WD/T1w_restore_F99
  fslmaths $WD/T1w_restore_F99 -thr 0 $WD/T1w_restore_F99


  # -------------------------------------------------------------- #
  # STEP 5: use the matlab script compare_source_ref_intensities.m
  # -------------------------------------------------------------- #

  # fit splines (or polynomial) to describe relationship between the two contrasts
  $matlabbin/matlab -nojvm -nodisplay -nosplash -r "try; cd $rootDir/proc/ex_vivo_template; fit_voxel_intensities('$WD','$rootDir','$flgFit'); catch ME; disp('ai, something went wrong.'); rethrow(ME); end; quit"
  # threshold the fitted template
  fslmaths $WD/McLaren_inv_fit -thr 0 $WD/McLaren_inv
  # create a strict, but smooth, weighting mask
  fslmaths ${ref} -thr 160 -bin -s 0.5 -mul -1 -add 2 $WD/McLaren_weighting
  # everything inside the weighting mask is taken from the fitted template
  # and everything outside is taken from the orignal template
  fslmaths $WD/McLaren_inv -mul $WD/McLaren_weighting -thr 0 $WD/McLaren_inv
  # dilate the edge, just to make it a bit brighter
  fslmaths $WD/McLaren_inv_fit -thr 0 -dilF -min $WD/McLaren_inv $WD/McLaren_inv
  # and smoothly threshold to force zeros outside the brain
  fslmaths $WD/McLaren_inv -thr 10 -bin -s 0.5 $WD/McLaren_weighting
  fslmaths $WD/McLaren_inv -mul $WD/McLaren_weighting $WD/McLaren_inv


  # --------------------------------------------------------------- #
  # STEP 6: linear and non-linear registration to this new template
  # --------------------------------------------------------------- #

  # linear registration of the source image to the (inverted) reference
  flirt -dof 12 -ref $WD/McLaren_inv -refweight ${ref}_brain_mask -in $img -inweight $brainmask -omat $WD/source_to_refinv.mat

  # compare the costs (against the regular reference)
  costinv=$(flirt -ref $ref -in $img -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/source_to_refinv.mat | head -1 | cut -d' ' -f1)
  [[ $(echo $costref $costinv | awk '($1<$2){print "1"}') == 1 ]] && translin=$WD/source_to_ref.mat || translin=$WD/source_to_refinv.mat

  # spline interpolate according to the best registration
  applywarp --rel --interp=spline -i $img -r $ref --premat=$translin -o $WD/T1w_restore_F99lin
  fslmaths $WD/T1w_restore_F99lin -thr 0 $WD/T1w_restore_F99lin

  # non-linear registration to the inverted reference
  fnirt --ref=$WD/McLaren_inv --refmask=${ref}_brain_mask --in=$img --intin=$WD/T1w_restore_F99lin --aff=$translin --fout=$WD/source_to_refinv_warp --config=$config

  # resample the source image and mask to the reference space
  applywarp --rel --interp=nn -i $brainmask -r $ref -w $WD/source_to_refinv_warp -o $WD/brainmask_F99
  applywarp --rel --interp=spline -i $img -r $ref -w $WD/source_to_refinv_warp -o $WD/T1w_restore_F99
  fslmaths $WD/T1w_restore_F99 -thr 0 $WD/T1w_restore_F99

done
