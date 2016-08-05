#!/usr/bin/env bash
set -e    # stop immediately on error


# ------------------------------ #
# usage
# ------------------------------ #

usage() {
  echo ""
  echo "Brain extract the F99 reference image based on McLaren reference."
  echo ""
  echo "example:"
  echo "      `basename $0` --all"
  echo "      `basename $0` --workdir=$(pwd) --F99img=F99 --betorig --biascorr"
  echo ""
  echo "usage: `basename $0`"
  echo "      [--all] : execute all sections --betorig --biascorr --betrestore"
  echo "          --refreg --brainmask"
  echo "      [--betorig] : rough brain extraction of the original F99 structural"
  echo "      [--refreg] : register to the reference and warp the refmask back"
  echo "      [--brainmask] : retrieve the brain mask from the refreg and polish"
  echo "      [--workdir=<working dir>] (default: <current directory>)"
  echo "      [--F99dir=<F99 structural dir>] (default: F99)"
  echo "      [--F99img=<F99 structural image>] (default: F99)"
  echo "      [--refname=<refreg name>] (default: SL)"
  echo "      [--refimg=<refreg reference image>] (default: McLaren)"
  echo "      [--refmask=<refreg referece brain mask>] (default: McLaren_brain_mask)"
  echo "      [--refmaskstrict=<strict refreg referece brain mask>]"
  echo "          (default: McLaren_brain_mask_strict)"
  echo "      [--scriptdir=<script dir>] (default: <current directory>)"
  echo "      [--config=<fnirt config file> (default: fnirt_1mm.cnf)"
  echo ""
}


# ------------------------------ #
# sub function to parse the input arguments
# ------------------------------ #
getoption() {
  sopt="--$1"
  shift 1
  for fn in $@ ; do
  	if [[ -n $(echo $fn | grep -- "^${sopt}=") ]] ; then
      echo $fn | sed "s/^${sopt}=//"
      return 0
    elif [[ -n $(echo $fn | grep -- "^${sopt}$") ]] ; then
      echo "TRUE"
      return 0
  	fi
  done
}


# ------------------------------ #
# process and test the input arguments, this is just an example
# ------------------------------ #

# if no arguments given, return the usage
if [[ $# -eq 0 ]] ; then usage; exit 0; fi

# if not given, retrieve directory of this script
[[ $0 == */* ]] && thisscript=$0 || thisscript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/$0

# if "--all" is given, run the default set
if [[ $(getoption "all" "$@") = "TRUE" ]] ; then
  # the default arguments associated with "--all" / "--nonlin"
  defaultset="--betorig --biascorr --betrestore --refreg --brainmask"
  echo "running the complete set of instructions: $defaultset"
  # replace "--all" with the default argument set
  newargs=$(echo "${@//--all/$defaultset}")
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
[[ -n $duplicates ]] && echo "\nError, repetitions found in the arguments:\n$@\n${duplicates}\n" && exit 1


# ------------------------------ #
# parse the input arguments, or retrieve default settings
# ------------------------------ #

# parse arguments
workdir=$(getoption "workdir" "$@")
F99dir=$(getoption "F99dir" "$@")
F99img=$(getoption "F99img" "$@")
refname=$(getoption "refname" "$@")
refimg=$(getoption "refimg" "$@")
refmask=$(getoption "refmask" "$@")
refmaskstrict=$(getoption "refmaskstrict" "$@")
scriptdir=$(getoption "scriptdir" "$@")
config=$(getoption "config" "$@")

# default definitions
[[ -z $workdir ]] && workdir="."
[[ -z $F99img ]] && F99img="F99"
[[ -z $F99dir ]] && F99dir="${F99img%/*}"
[[ -z $F99dir ]] && F99dir="F99"
F99img=${F99img##*/}  # remove the directory at the beginning
F99img=${F99img%%.*}  # remove the extension at the end
[[ -z $refname ]] && refname="McLaren"
refdir="$refname"
[[ -z $refimg ]] && refimg="McLaren"
[[ -z $refmask ]] && refmask="${refimg}_brain_mask"
[[ -z $refmaskstrict ]] && refmaskstrict="${refmask}_strict"
[[ -z $scriptdir ]] && scriptdir="."
[[ -z $config ]] && config="fnirt_1mm.cnf"

# prepad the directory if none is given
[[ $F99dir != */* ]] && F99dir=$workdir/$F99dir
[[ $diffdir != */* ]] && diffdir=$workdir/$diffdir
[[ $refdir != */* ]] && refdir=$workdir/$refdir
[[ $refimg != */* ]] && refimg=$scriptdir/$refimg
[[ $refmask != */* ]] && refmask=$scriptdir/$refmask
[[ $config != */* ]] && config=$scriptdir/$config


# ------------------------------ #
# the instructions are coded below
# ------------------------------ #

# first rough brain extraction
if [[ $(getoption "betorig" "$@") = "TRUE" || $(getoption "betrestore" "$@") = "TRUE" ]] ; then
  # input:  original F99img
  # output: {F99img}_brain_mask

  # definitions
  base=$F99dir/$F99img
  if [[ $(getoption "betorig" "$@") = "TRUE" ]] ; then
    img=$F99dir/$F99img
  else
    img=$F99dir/${F99img}_restore
  fi

  echo "brain extraction of: $img"

  # find the number of voxels
  xdim=$(fslhd -x $img | grep "nx = " | tr -d "[:alpha:][:space:][:punct:]")
  ydim=$(fslhd -x $img | grep "ny = " | tr -d "[:alpha:][:space:][:punct:]")
  zdim=$(fslhd -x $img | grep "nz = " | tr -d "[:alpha:][:space:][:punct:]")
  # find sensible centroids to initialise bet
  xhalf=$(echo $xdim | awk '{print $1/2}')
  ypost=$(echo $ydim | awk '{print $1/6}')
  yhalf=$(echo $ydim | awk '{print $1/2}')
  yant=$(echo $ydim | awk '{print $1*2/3}')
  zhalf=$(echo $zdim | awk '{print $1/2}')
  zhigh=$(echo $zdim | awk '{print $1*2/3}')

  # run bet centred at an anterior position
  bet $img ${base}_brain_ant -m -n -r 30 -f 0.35 -c $xhalf $yant $zhigh
  # and once more at a central (default) position
  bet $img ${base}_brain -m -n -r 30 -f 0.3 -c $xhalf $yhalf $zhalf
  # and once more at a posterior position
  bet $img ${base}_brain_post -m -n -r 30 -f 0.2 -c $xhalf $ypost $zhalf

  # add them and binarise
  fslmaths ${base}_brain_mask -add ${base}_brain_ant_mask -add ${base}_brain_post_mask -bin ${base}_brain_mask

  # find the extent of the brain mask
  str=$(fslstats ${base}_brain_mask -C -w)

  # extract coordinates for frontal pole centroid
  x=$(echo $str | awk '{print $1}')
  y=$(echo $str | awk '{print $2+$7*4/9}')
  z=$(echo $str | awk '{print $3+$9/8}')

  # frontal pole bet
  bet $img ${base}_Fpole -m -r 25 -f 0.7 -c $x $y $z

  #if [[ $(getoption "betrestore" "$@") = "TRUE" ]] ; then
    # erode, cluster, ignore olfactory bulb, and dilate
    #thr=$(fslstats ${base}_Fpole -P 20)
    #fslmaths ${base}_Fpole -thr $thr -bin -ero -ero ${base}_Fpole
    #cluster --in=${base}_Fpole --thresh=0.5 --no_table --connectivity=6 --minextent=10000 --oindex=${base}_Fpole
    #fslmaths ${base}_Fpole -bin -dilF -s 0.5 -thr 0.002 -bin ${base}_Fpole_mask
  #fi

  if [[ $(getoption "betorig" "$@") = "TRUE" ]] ; then
    # combine brain mask with all the poles
    fslmaths ${base}_brain_mask -add ${base}_Fpole_mask -bin ${base}_brain_mask

  else
    # extract coordinates for temporal pole centroid
    xL=$(echo $str | awk '{print $1-$5*2/7}')
    xR=$(echo $str | awk '{print $1+$5*2/7}')
    y=$(echo $str | awk '{print $2+$7/6}')
    z=$(echo $str | awk '{print $3-$9*2/6}')

    # temporal poles bet
    bet $img ${base}_TpoleL -m -n -r 25 -f 0.5 -c $xL $y $z
    bet $img ${base}_TpoleR -m -n -r 25 -f 0.5 -c $xR $y $z

    # combine brain mask with all the poles
    fslmaths ${base}_brain_mask -add ${base}_Fpole_mask -add ${base}_TpoleL_mask -add ${base}_TpoleR_mask -bin ${base}_brain_mask
  fi

  # store intermediate result, and the brain
  imcp ${base}_brain_mask ${base}_brain_mask_bet
  fslmaths $img -mas ${base}_brain_mask_bet ${base}_brain

  # exclude high-intensity clusters in the mask
  if [[ $(getoption "betorig" "$@") = "TRUE" ]] ; then
    thr=$(fslstats ${base}_brain -p 98)
    cluster --in=${base}_brain --thresh=$thr --no_table --connectivity=26 --omean=${base}_2remove
    thr=$(fslstats ${base}_brain -p 99.5) # remove two brightest clusters (eyes)
  else
    thr=$(fslstats ${base}_brain -p 99.9)
    cluster --in=${base}_brain --thresh=$thr --no_table --connectivity=26 --oindex=${base}_2remove
    thr=$(fslstats ${base}_brain -R | awk '{print $2-1}') # remove only the two biggest clusters (eyes)
  fi
  fslmaths ${base}_2remove -thr $thr -bin -dilF ${base}_2remove
  fslmaths ${base}_brain_mask -sub ${base}_2remove -bin ${base}_brain_mask

  # polish and smooth the brain mask a bit
  fslmaths ${base}_brain_mask -fillh -s 0.5 -thr 0.45 -bin ${base}_brain_mask

  # clean up
  imrm ${base}_brain_ant_mask ${base}_brain_post_mask ${base}_Fpole ${base}_Fpole_mask ${base}_TpoleL_mask ${base}_TpoleR_mask ${base}_2remove

  echo "  done"

fi


# bias correct the corrected image
if [[ $(getoption "biascorr" "$@") = "TRUE" ]] ; then
  # input:  F99img
  # output: {F99img}_restore
  img=$F99dir/$F99img
  echo "bias correcting image: $img"

  # smoothness definitions
  sigma=3
  FWHM=$(echo "2.3548 * $sigma" | bc)

  # run RobustBiasCorr
  $scriptdir/RobustBiasCorr.sh \
    --in=$img \
    --workingdir=$F99dir/biascorr \
    --brainmask=${img}_brain_mask \
    --basename=F99 \
    --FWHM=$FWHM \
    --type=1 \
    --forcestrictbrainmask="FALSE" --ignorecsf="FALSE"

  # copy the restored image and bias field, and remove working directory
  imcp $F99dir/biascorr/F99_restore ${img}_restore
  imcp $F99dir/biascorr/F99_bias ${img}_bias
  rm -rf $F99dir/biascorr

  echo "  done"

fi


# reference registration
if [[ $(getoption "refreg" "$@") = "TRUE" ]] ; then
  # input:  {F99img}_restore
  # output: {F99img}_brain_mask
  img=$F99dir/${F99img}_restore
  base=$F99dir/$F99img
  echo "register to the reference: $refname"

  # make a folder for the transformations
  mkdir -p $workdir/transform/
  mkdir -p $refdir/

  # perform linear registration of the F99 to reference
  #flirt -dof 12 -ref $refimg -refweight $refmask -in $img -inweight ${base}_brain_mask -omat $workdir/transform/${F99img}_2${refname}.mat
  flirt -dof 12 -ref $refimg -refweight $refimg -in $img -inweight ${base}_brain_mask -omat $workdir/transform/${F99img}_2${refname}.mat

  # use spline interpolation to apply the linear transformation matrix
  #applywarp --rel --interp=spline -i $img -r $refimg --premat=$workdir/transform/${F99img}_2${refname}.mat -o $refdir/${F99img}_lin

  # and now non-linear
  echo "using the mask: $refmaskstrict"
  fnirt --ref=$refimg --refmask=$refmaskstrict --in=$img --aff=$workdir/transform/${F99img}_2${refname}.mat --fout=$workdir/transform/${F99img}_2${refname}_warp --config=$config

  # use spline interpolation to apply the warp field
  applywarp --rel --interp=spline -i $img -r $refimg -w $workdir/transform/${F99img}_2${refname}_warp -o $refdir/$F99img

  # and now invert the warp field
  invwarp -w $workdir/transform/${F99img}_2${refname}_warp -o $workdir/transform/${refname}_2${F99img}_warp -r $img

  # ditch the warp coeficient and log
  imrm ${img}_warpcoef
  rm ${img}_to_*.log

  echo "  done"

fi

# retrieve and polish the brain mask
if [[ $(getoption "brainmask" "$@") = "TRUE" ]] ; then
  # input:  {F99img}_restore, {F99img}_brain_mask
  # output: {F99img}_brain_mask
  img=$F99dir/${F99img}_restore
  base=$F99dir/$F99img
  echo "retrieve and polish the brain mask based on: $refname"

  # warp the brain mask from reference to F99
  applywarp --rel --interp=nn -i $refmask -r $img -w $workdir/transform/${refname}_2${F99img}_warp -o ${base}_brain_mask
  imcp ${base}_brain_mask ${base}_brain_mask_$refname
  applywarp --rel --interp=nn -i $refmaskstrict -r $img -w $workdir/transform/${refname}_2${F99img}_warp -o ${base}_brain_mask_strict
  imcp ${base}_brain_mask_strict ${base}_brain_mask_strict_$refname

  # erode and select
  fslmaths ${base}_brain_mask -s 1 -thr 0.9 -bin ${base}_brain_mask_edge
  fslmaths ${base}_brain_mask -sub ${base}_brain_mask_edge -bin ${base}_brain_mask_edge
  fslmaths $img -mas ${base}_brain_mask_edge ${base}_brain_edge

  # find nasal bits of eyes
  fslmaths ${base} -s 1 -mas ${base}_brain_mask_edge ${base}_blur
  fslmaths ${img} -s 1 -mas ${base}_brain_mask_edge ${img}_blur
  fslmaths ${base}_blur -mul ${img}_blur -div 1000 -roi 0 -1 153 -1 0 -1 0 -1 -thr 5 -bin ${base}_eyes_nasal

  # find posterior bits of eyes
  fslmaths ${base} -mul ${img} -mas ${base}_brain_mask_edge -div 1000 -roi 0 -1 133 -1 0 -1 0 -1 -thr 8 -bin ${base}_eyes_post
  fslmaths ${img} -mas ${base}_brain_mask_edge -roi 0 -1 133 -1 0 -1 0 -1 -thr 200 -bin -add ${base}_eyes_post -bin ${base}_eyes_post
  fslmaths ${base}_brain_mask -binv -add ${base}_eyes_post -bin ${base}_eyes_post
  cluster --in=${base}_eyes_post --thresh=0.5 --no_table --connectivity=6 --minextent=10000 --oindex=${base}_eyes_post
  fslmaths ${base}_eyes_post -mas ${base}_brain_mask -bin ${base}_eyes_post

  # remove these bits
  fslmaths ${base}_brain_mask -sub ${base}_eyes_nasal -sub ${base}_eyes_post ${base}_brain_mask

  # smooth out the brain mask (and just ever so slightly dilate)
  fslmaths ${base}_brain_mask -s 1 -thr 0.45 -bin ${base}_brain_mask

  # exclude again the posterior eye bits
  cluster --in=${base}_eyes_post --thresh=0.5 --minextent=100 --no_table --oindex=${base}_eyes_post
  fslmaths ${base}_eyes_post -bin ${base}_eyes_post
  fslmaths ${base}_brain_mask -sub ${base}_eyes_post -bin ${base}_brain_mask

  # extract the brain
  fslmaths $img -mas ${base}_brain_mask ${base}_brain

  # and make a strict mask
  thr=$(fslstats ${base}_brain -P 5)
  cluster --in=${base}_brain --thresh=$thr --no_table --connectivity=6 --minextent=10000 --oindex=${base}_brain_mask_strict
  fslmaths ${base}_brain_mask_strict -bin -fillh -s 0.5 -thr 0.5 -bin -mas ${base}_brain_mask -fillh ${base}_brain_mask_strict

  # clean up
  imrm ${base}_brain_edge ${base}_brain_mask_edge ${base}_blur ${img}_blur ${base}_eyes_nasal ${base}_eyes_post

  echo "  done"

fi
