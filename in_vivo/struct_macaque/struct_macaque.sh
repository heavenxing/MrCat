#!/usr/bin/env bash
set -e    # stop immediately on error

# preprocessing of a macaque structural image
# 1. brain extraction
# 2. bias correction
# 3. reference registration
# these steps are dependent on each other and could therefore be repeated for
# the best results

# TODO: calculate the flirt cost based on the brain extracted image

# ------------------------------ #
# usage
# ------------------------------ #

usage() {
cat <<EOF

Preprocess macaque structural MRI. Brain extraction, bias correction, and
  reference registration.

example:
  struct_macaque.sh --subjdir=MAC1 --all
  struct_macaque.sh --subjdir=MAC1 --once
  struct_macaque.sh --subjdir=MAC1 --structimg=struct/struct --betorig --biascorr

usage: struct_macaque.sh
  instructions:
    [--all] : execute all inctructions, twice: --robustfov --betorig --biascorr
      --betrestore --register --brainmask --biascorr --register --brainmask
    [--once] : execute all instructions once: --robustfov --betorig --biascorr
      --betrestore --register --brainmask
    [--robustfov] : robust field-of-view cropping
    [--betorig] : rough brain extraction of the original structural
    [--betrestore] : brain extraction of the restored structural
    [--biascorr] : correct the spatial bias in signal intensity
    [--register] : register to the reference and warp the refmask back
    [--brainmask] : retrieve the brain mask from the reference and polish
  settings:
    [--subjdir=<subject dir>] default: <current directory>
    [--structdir=<structural dir>] default: <subjdir>/struct
    [--structimg=<structural image>] default: <structdir>/struct
      the <structdir> can be inferred from <structimg>, if provided
    [--structmask=<structural brain mask>] default: <structimg>_brain_mask
    [--transdir=<transform dir>] default: <subjdir>/transform
    [--scriptdir=<script dir>] default: <parent directory of struct_macaque.sh>
      path to bet_macaque.sh and robustfov_macaque.sh scripts
    [--HCPdir=<HCP dir>] default: <parent directory of struct_macaque.sh>
      path to RobustBiasCorr.sh, and default for fnirt config
    [--refdir=<reference dir>] default: <inferred from refimg, or scriptdir>
      path to reference images
    [--fovmm=<xsize ysize zsize> default: 128 128 64
      field-of-view in mm, for robustfov_macaque
    [--config=<fnirt config file> default: <scriptdir>/fnirt_1mm.cnf
    [--refspace=<reference space name>] default: F99, alternative: SL, MNI
    [--refimg=<ref template image>] default: <scriptdir>/<refspace>/McLaren
    [--refmask=<reference brain mask>] default: <refimg>_brain_mask
    [--refweightflirt=<ref weights for flirt>] default <refmask>
    [--refmaskfnirt=<ref brain mask for fnirt>] default <refmask>
    [--flirtoptions]=<extra options for flirt>] default none

EOF
}


# ------------------------------ #
# process and test the input arguments
# ------------------------------ #

# if no arguments given, or help is requested, return the usage
[[ $# -eq 0 ]] || [[ $@ =~ --help ]] && usage && exit 0

# if not given, retrieve directory of this script
[[ $0 == */* ]] && thisscript=$0 || thisscript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/$0

# if "--all" is given, run the default set
if [[ $@ =~ --all$ ]] || [[ $@ =~ "--all " ]] ; then
  # the default arguments associated with "--all" / "--nonlin"
  defaultset="--robustfov --betorig --biascorr --betrestore --register --brainmask --biascorr --register --brainmask"
  echo "running the complete set of instructions: $defaultset"
  # replace "--all" with the default argument set
  newargs=$(echo "${@//--all/$defaultset}")
  # execute this script with the default argument set, and passing others
  sh $thisscript $newargs
  exit 0
elif [[ $@ =~ --once$ ]] || [[ $@ =~ "--once " ]] ; then
  # the default arguments associated with "--all" / "--nonlin"
  defaultset="--robustfov --betorig --biascorr --betrestore --register --brainmask"
  echo "running the complete set of instructions: $defaultset"
  # replace "--once" with the default argument set
  newargs=$(echo "${@//--once/$defaultset}")
  # execute this script with the default argument set, and passing others
  sh $thisscript $newargs
  exit 0
fi

# run each instruction on its own (with the same definitions)
definitionargs=$(echo "$@" | tr " " "\n" | grep '=') || true
instructargs=$(echo "$@" | tr " " "\n" | grep -v '=') || true
if [[ $(echo "$instructargs" | wc -w) -gt 1 ]] ; then
  # this ensures the instructions are executed as specified, not as coded
  for instr in $instructargs ; do
    sh $thisscript $definitionargs $instr
  done
  exit 0
fi

# count and grep the number of argument repetitions (ignoring after "=")
duplicates=$(echo "$@" | tr " " "\n" | awk '{ gsub("=.*","="); print $0}' | sort | uniq -c | grep -v '^ *1 ') || true   # "|| true" is added to ignore the non-zero exit code of grep (and avoid the script the stop because of "set -e")
# now test if any duplicates were found, and if so, give an error
[[ -n $duplicates ]] && >&2 echo "\nError, repetitions found in the arguments:\n$@\n${duplicates}\n" && exit 1


# ------------------------------ #
# arguments and defaults
# ------------------------------ #
# set defaults
instr=""
subjdir="."
structimg="struct"
structmask=""
[[ -n $MRCATDIR ]] && scriptdir=$MRCATDIR/in_vivo && HCPdir=$MRCATDIR/HCP_scripts && refdir=$MRCATDIR/ref_macaque
transdir="transform"
fovmm="128 128 64"
config="fnirt_1mm.cnf"
refspace="F99"
refimg="McLaren"
flirtoptions=""

# parse the input arguments
for a in "$@" ; do
  case $a in
    --subjdir=*)        subjdir="${a#*=}"; shift ;;
    --structdir=*)      structdir="${a#*=}"; shift ;;
    --structimg=*)      structimg="${a#*=}"; shift ;;
    --structmask=*)     structmask="${a#*=}"; shift ;;
    --transdir=*)       transdir="${a#*=}"; shift ;;
    --scriptdir=*)      scriptdir="${a#*=}"; shift ;;
    --HCPdir=*)         HCPdir="${a#*=}"; shift ;;
    --refdir=*)         refdir="${a#*=}"; shift ;;
    --fovmm=*)          fovmm="${a#*=}"; shift ;;
    --config=*)         config="${a#*=}"; shift ;;
    --refspace=*)       refspace="${a#*=}"; shift ;;
    --refimg=*)         refimg="${a#*=}"; shift ;;
    --refmask=*)        refmask="${a#*=}"; shift ;;
    --refweightflirt=*) refweightflirt="${a#*=}"; shift ;;
    --refmaskfnirt=*)   refmaskfnirt="${a#*=}"; shift ;;
    --flirtoptions=*)   flirtoptions="${a#*=}"; shift ;;
    *)                  instr="$instr $a"; shift ;; # instruction argument
  esac
done

# input dependent defaults
[[ -z $structdir ]] && structdir="${structimg%/*}"
[[ -z $structdir ]] && structdir="struct"
structimg=${structimg##*/}    # remove the directory
structimg=${structimg%%.*}    # remove the extension
structmask=${structmask%%.*}  # remove the extension
spacedir="$refspace"
refimg=${refimg%%.*}  # remove the extension
[[ -z $refmask ]] && refmask="${refimg}_brain_mask"
refmask=${refmask%%.*}  # remove the extension
#baserefimg=${refimg##*/}    # remove the directory
#if [[ ${baserefimg%%.*} == "McLaren" ]] ; then
#  [[ -z $refweightflirt ]] && refweightflirt="$refimg"
#  [[ -z $refmaskfnirt ]] && refmaskfnirt="${refmask}_strict"
#fi

# sort the location of the different script directories
[[ -z $refweightflirt ]] && refweightflirt="$refmask"
[[ -z $refmaskfnirt ]] && refmaskfnirt="$refmask"
[[ -z $scriptdir ]] && scriptdir="$(cd "$(dirname ${BASH_SOURCE[0]})"/.. && pwd)"
[[ -z $HCPdir ]] && HCPdir=$(cd $scriptdir/../HCP_scripts && pwd)
[[ ! -d $HCPdir ]] && HCPdir=$scriptdir
[[ -z $refdir ]] && refdir=$(cd $scriptdir/../ref_macaque && pwd)
[[ ! -d $refdir ]] && refdir=$scriptdir

# prepad the directory if none is given
[[ $config != */* ]] && config=$HCPdir/$config
[[ $structdir != */* ]] && structdir=$subjdir/$structdir
[[ $spacedir != */* ]] && spacedir=$subjdir/$spacedir
[[ $transdir != */* ]] && transdir=$subjdir/$transdir
[[ $refimg != */* ]] && refimg=$refdir/$refspace/$refimg
[[ $refmask != */* ]] && refmask=$refdir/$refspace/$refmask
[[ $refweightflirt != */* ]] && refweightflirt=$refdir/$refspace/$refweightflirt
[[ $refmaskfnirt != */* ]] && refmaskfnirt=$refdir/$refspace/$refmaskfnirt


# ------------------------------ #
# the instructions are coded below
# ------------------------------ #

# first rough brain extraction
if [[ $instr =~ --robustfov$ ]] ; then
  # input:  original structimg
  # output: (cropped) structimg with robust field-of-view

  # call robustfov_macaque.sh to ensure a robust field-of-view
  $scriptdir/robustfov_macaque.sh $structdir/$structimg -m $fovmm -f

fi


# first rough brain extraction
if [[ $instr =~ --betorig$ ]] || [[ $instr =~ --betrestore$ ]] ; then
  # input:  original or restored structimg
  # output: {structimg}_brain_mask

  # definitions
  if [[ $instr =~ --betorig$ ]] ; then
    img=$structdir/$structimg
    fbrain=0.2
    niter=3
  else
    img=$structdir/${structimg}_restore
    fbrain=0.25
    niter=10
  fi
  base=$structdir/$structimg
  [[ -z $structmask ]] && structmask=${base}_brain_mask

  # call bet_macaque.sh for an initial brain extraction
  $scriptdir/bet_macaque.sh $img $base --fbrain $fbrain --niter $niter

  # remove old brain extractions, and create new ones
  imrm ${base}_brain ${img}_brain
  [[ -r ${base}.nii.gz ]] && fslmaths $base -mas $structmask ${base}_brain
  [[ -r ${img}.nii.gz ]] && fslmaths $img -mas $structmask ${img}_brain

  # copy the brain mask for later inspection
  imcp $structmask ${structmask}_bet

fi


# bias correct the corrected image
if [[ $instr =~ --biascorr$ ]] ; then
  # input:  structimg
  # output: {structimg}_restore
  base=$structdir/${structimg}
  [[ -z $structmask ]] && structmask=${base}_brain_mask
  echo "bias correcting image: $base"

  # ignore dark voxels
  thr=$(fslstats ${base}_brain -P 5)
  cluster --in=${base}_brain --thresh=$thr --no_table --connectivity=6 --minextent=10000 --oindex=${structmask}_biascorr
  # and the super bright
  thr=$(fslstats ${base}_brain -P 99.8)
  fslmaths ${structmask}_biascorr -bin -uthr $thr ${structmask}_biascorr

  # smoothness definitions
  sigma=3
  FWHM=$(echo "2.3548 * $sigma" | bc)

  # run RobustBiasCorr
  $HCPdir/RobustBiasCorr.sh \
    --in=$base \
    --workingdir=$structdir/biascorr \
    --brainmask=${structmask}_biascorr \
    --basename=struct \
    --FWHM=$FWHM \
    --type=1 \
    --forcestrictbrainmask="FALSE" --ignorecsf="FALSE"

  # copy the restored image and bias field, and remove working directory
  imcp $structdir/biascorr/struct_restore ${base}_restore
  imcp $structdir/biascorr/struct_bias ${base}_bias
  rm -rf $structdir/biascorr

  # clean up
  imrm ${structmask}_biascorr

  echo "  done"

fi


# reference registration
if [[ $instr =~ --register$ ]] ; then
  base=$structdir/${structimg}
  [[ -z $structmask ]] && structmask=${base}_brain_mask
  echo "register ${base}_restore to reference: $refimg"

  # ensure the reference and transformation directories exist
  mkdir -p $spacedir
  mkdir -p $transdir

  # perform linear registration of the structural to reference
  echo "  linear registration"
  flirt -dof 12 -ref $refimg -refweight $refweightflirt -in ${base}_restore -inweight $structmask -omat $transdir/${structimg}_to_${refspace}.mat $flirtoptions

  # check cost of this registration
  cost=$(flirt -ref $refimg -in ${base}_restore -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $transdir/${structimg}_to_${refspace}.mat | head -1 | cut -d' ' -f1)

  # decide if flirt is good enough or needs another try
  if [[ $(echo $cost | awk '($1>0.9){print 1}') ]] ; then
    echo "  registration is poor: the cost is $cost"
    echo "  for reference, a value of 0.8 or lower would be nice"
    echo "  rerunning linear registration with restricted search"

    # see if the original flirt was run without search
    if [[ $flirtoptions =~ -nosearch ]] ; then
      # remove the -nosearch option, but use a restricted schedule (simple3D)
      flirt -dof 12 -ref $refimg -refweight $refweightflirt -in ${base}_restore -inweight $structmask -omat $transdir/${structimg}_to_${refspace}_restricted.mat -schedule $FSLDIR/etc/flirtsch/simple3D.sch ${flirtoptions//-nosearch/}
    else
      # run flirt without search
      flirt -dof 12 -ref $refimg -refweight $refweightflirt -in ${base}_restore -inweight $structmask -omat $transdir/${structimg}_to_${refspace}_restricted.mat -nosearch $flirtoptions
    fi

    # calculate cost of restricted registration
    costrestr=$(flirt -ref $refimg -in ${base}_restore -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $transdir/${structimg}_to_${refspace}_restricted.mat | head -1 | cut -d' ' -f1)

    # check if the new registration is actually better
    echo "  restricted registration cost is $costrestr"
    if [[ $(echo $cost $costrestr | awk '($1<$2){print 1}') ]] ; then
      # reject new registration
      echo "  keeping original registration, but please be warned of poor results"
      rm -rf $transdir/${structimg}_to_${refspace}_restricted.mat
    else
      if [[ $(echo $costrestr | awk '($1>0.9){print 1}') ]] ; then
        echo "  continuing, but please be warned of poor registration results"
      else
        echo "  restricted registration is accepted"
      fi
      # use new registration
      mv -f $transdir/${structimg}_to_${refspace}_restricted.mat $transdir/${structimg}_to_${refspace}.mat
    fi

  else
    echo "  the linear registration cost is $cost"
  fi

  # invert linear transformation
  convert_xfm -omat $transdir/${refspace}_to_${structimg}.mat -inverse $transdir/${structimg}_to_${refspace}.mat

  # use spline interpolation to apply the linear transformation matrix
  applywarp --rel --interp=spline -i ${base}_restore -r $refimg --premat=$transdir/${structimg}_to_${refspace}.mat -o $spacedir/${structimg}_restore_lin
  fslmaths $spacedir/${structimg}_restore_lin -thr 0 $spacedir/${structimg}_restore_lin
  applywarp --rel --interp=nn -i $refmask -r $base --premat=$transdir/${refspace}_to_${structimg}.mat -o ${structmask}_${refspace}lin

  # now preform non-linear registration
  echo "  non-linear registration"
  #fnirt --ref=$refimg --refmask=$refmaskfnirt --in=${base}_restore --inmask=$structmask --aff=$transdir/${structimg}_to_${refspace}.mat --fout=$transdir/${structimg}_to_${refspace}_warp --config=$config
  fnirt --ref=$refimg --refmask=$refmaskfnirt --in=${base}_restore --aff=$transdir/${structimg}_to_${refspace}.mat --fout=$transdir/${structimg}_to_${refspace}_warp --config=$config

  # use spline interpolation to apply the warp field
  echo "  applying and inverting warp"
  applywarp --rel --interp=spline -i ${base}_restore -r $refimg -w $transdir/${structimg}_to_${refspace}_warp -o $spacedir/${structimg}_restore
  fslmaths $spacedir/${structimg}_restore -thr 0 $spacedir/${structimg}_restore

  # invert the warp field
  invwarp -w $transdir/${structimg}_to_${refspace}_warp -o $transdir/${refspace}_to_${structimg}_warp -r ${base}

  # and ditch the warp coeficient and log
  rm -f ${base}*warpcoef*
  mv -f ${base}*to_*.log $transdir/

  echo "  done"
fi


# retrieve and polish the brain mask
if [[ $instr =~ --brainmask$ ]] ; then
  # input:  {structimg}_restore, {structimg}_brain_mask
  # output: {structimg}_brain_mask
  base=$structdir/${structimg}
  [[ -z $structmask ]] && structmask=${base}_brain_mask
  echo "retrieve and polish the brain mask based on: $refimg"

  # warp the brain mask from reference to struct
  applywarp --rel --interp=nn -i $refmask -r $base -w $transdir/${refspace}_to_${structimg}_warp -o $structmask
  imcp $structmask ${structmask}_$refspace

  # smooth out the brain mask (and just ever so slightly dilate)
  fslmaths $structmask -s 1 -thr 0.45 -bin $structmask

  # extract the brain
  fslmaths ${base}_restore -mas $structmask ${base}_brain

  # remove old brain extractions, and create new ones
  imrm ${base}_brain ${base}_restore_brain
  [[ -r ${base}.nii.gz ]] && fslmaths $base -mas $structmask ${base}_brain
  [[ -r ${base}_restore.nii.gz ]] && fslmaths ${base}_restore -mas $structmask ${base}_restore_brain

  # and make a strict mask
  thr=$(fslstats ${base}_brain -P 5)
  cluster --in=${base}_brain --thresh=$thr --no_table --connectivity=6 --minextent=10000 --oindex=${structmask}_strict
  fslmaths ${structmask}_strict -bin -fillh -s 0.5 -thr 0.5 -bin -mas $structmask -fillh ${structmask}_strict

  echo "  done"

fi
