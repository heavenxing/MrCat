#!/usr/bin/env bash
set -e    # stop immediately on error


# ------------------------------ #
# usage
# ------------------------------ #

usage() {
  echo ""
  echo "Correct and brain extract the original macaque_25_model-MNI image."
  echo "Most important outputs: <basename>_corr, and <basename>_brain_mask."
  echo ""
  echo "examples:"
  echo "      `basename $0` --all"
  echo "      `basename $0` --workingdir=$(pwd)"
  echo "          --orig=macamacaque_25_model-MNI --basename=MNI --rescale"
  echo "          --fliplin --corrflip --bet --corrCSF --bet --corrspots --betlib"
  echo "          --corrCSF --betlib --downsamp --biascorr"
  echo ""
  echo "usage: `basename $0`"
  echo "      [--all] : perform all steps:"
  echo "          --rescale --fliplin --corrflip --bet --corrCSF --bet --corrspots"
  echo "          --betlib --corrCSF --betlib --downsamp --biascorr"
  echo "      [--lin] : same as --all"
  echo "      [--nonlin] : perform all steps including nonlin, beware this takes hours:"
  echo "          --rescale --fliplin --corrflip --bet --flipnonlin --corrflip --bet"
  echo "          --corrCSF --bet --corrspots --betlib --corrCSF --betlib --downsamp"
  echo "          --biascorr"
  echo "      [--rescale] : copy and rescale the original image"
  echo "      [--fliplin] : flip and linear register (12 dof) the image"
  echo "      [--corrflip] : initial correction, taking the minimal value of the"
  echo "          rescaled and flipped images (--fliplin or --flipnonlin)"
  echo "      [--bet] : robust brain extraction of --betinput=<image>"
  echo "          (default: <basename>_corr) using multiple centroids"
  echo "      [--betlib] : same as --bet, but now with slightly more liberal tweaks,"
  echo "          only works after all corrections"
  echo "      [--flipnonlin] : non-linear registration based on --fliplin and --bet"
  echo "      [--corrCSF] : correction of bright CSF, uses fast,"
  echo "          based on --corrflip and --bet"
  echo "      [--corrspots] : correction of spots and edges"
  echo "          based on --corrflip or --corrCSF and --bet"
  echo "      [--downsamp] : down-sample <basename>_corr and masks to 0.5 and 1mm"
  echo "      [--biascorr] : correct the spatial intensity bias over the whole image"
  echo "          please note that this image is pretty homogeneous of itself,"
  echo "          so the bias restored image might introduce filtering artefacts"
  echo "      [--workingdir=<working dir>] (default: <current directory>)"
  echo "      [--scriptdir=<script dir>] where to find RobustBiasCorr.sh,"
  echo "          only needed for --biascorr (default: <current directory>)"
  echo "      [--orig]=<original image> (default: macaque_25_model-MNI)"
  echo "      [--basename=<base name of output>] (default: MNI)"
  echo "      [--flipimg=<flipped image> for --corrflip (default: <basename>_flip)"
  echo "      [--betinput=<image to bet> for --bet and --betlib"
  echo "          (default: <basename>_corr)"
  echo "      [--roicorrflip=<restrictive roi> as input for fslmaths in --corrflip,"
  echo "          use \"_\" not spaces (default: 0_-1_207_-1_0_-1_0_-1)"
  echo "      [--roicorrCSF=<restrictive roi> as input for fslmaths in --corrCSF,"
  echo "          use \"_\" not spaces (default: 0_-1_240_64_75_38_0_-1)"
  echo "      [--olfactbulb={TRUE,FALSE (default)} include (TRUE) or exclude the bulb"
  echo "      [--config=<fnirt config file> for --nonlin (default: fnirt_1mm.cnf)"
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

# if "--all" or "--lin" is given, run the default set
if [[ $(getoption "all" "$@") = "TRUE" || $(getoption "lin" "$@") = "TRUE" ]] ; then
  # the default arguments associated with "--all" / "--lin"
  defaultset="--rescale --fliplin --corrflip --bet --corrCSF --bet --corrspots --betlib --corrCSF --betlib --downsamp --biascorr"
  echo "running the linear set of instructions: $defaultset"
  # replace "--all" and "--lin" with the default argument set
  newargs=$(echo "${@//--all/$defaultset}")
  newargs=$(echo "${newargs//--lin/$defaultset}")
  # execute this script with the default argument set, and passing others
  sh $thisscript $newargs
  exit 0
# run the linear set if requested
elif [[ $(getoption "nonlin" "$@") = "TRUE" ]] ; then
  # the default arguments associated with "--nonlin"
  defaultset="--rescale --fliplin --corrflip --bet --flipnonlin --corrflip --bet --corrCSF --bet --corrspots --betlib --corrCSF --betlib --downsamp --biascorr"
  echo "running the linear set of instructions: $defaultset"
  # replace "--nonlin" with the default argument set
  newargs=$(echo "${@//--nonlin/$defaultset}")
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
WD=$(getoption "workingdir" "$@")
SD=$(getoption "scriptdir" "$@")
orig=$(getoption "orig" "$@")
MNI=$(getoption "basename" "$@")
flipimg=$(getoption "flipimg" "$@")
betinput=$(getoption "betinput" "$@")
config=$(getoption "config" "$@")
roicorrflip=$(getoption "roicorrflip" "$@")
roicorrCSF=$(getoption "roicorrCSF" "$@")

# default definitions
[[ -z $WD ]] && WD="."
mkdir -p $WD                                # ensure the working dir exists
[[ -z $SD ]] && SD=${thisscript%/*}
[[ -z $orig ]] && orig="macaque_25_model-MNI"
[[ $orig != */* ]] && orig=$WD/$orig        # prepad working dir if not given
[[ -z $MNI ]] && MNI="MNI"
[[ $MNI != */* ]] && MNI=$WD/$MNI           # prepad working dir if not given
[[ -z $flipimg ]] && flipimg=${MNI}_flip
[[ -z $betinput ]] && betinput=${MNI}_corr
[[ -z $config ]] && config="fnirt_1mm.cnf"
[[ $config != */* ]] && config=$SD/$config  # prepad script dir if not given
[[ -z $roicorrflip ]] && roicorrflip="0_-1_207_-1_0_-1_0_-1"
roicorrflip="${roicorrflip//_/ }"
[[ -z $roicorrCSF ]] && roicorrCSF="0_-1_240_64_75_38_0_-1"
roicorrCSF="${roicorrCSF//_/ }"


# ------------------------------ #
# the instructions are coded below
# ------------------------------ #

# rescale the image
if [[ $(getoption "rescale" "$@") = "TRUE" ]] ; then
  # input:  $orig
  # output: $MNI
  echo "rescale the image"

  # copy the image
  imcp $orig $MNI
  # and rescale intensity relative to range
  minmax=$(fslstats ${MNI} -R)
  minval=$(echo $minmax | awk '{print $1}')
  rangeval=$(echo $minmax | awk '{print $2-$1}')
  fslmaths $MNI -sub $minval -div $rangeval -mul 1000 -thr 0 $MNI

  echo "  done"
fi


# flip the image, and register
if [[ $(getoption "fliplin" "$@") = "TRUE" ]] ; then
  # input:  ${MNI}
  # output: ${MNI}_flip
  echo "flip and register the image"

  # copy the image and mask
  imcp ${MNI} ${MNI}_flip
  # swap left-right
  fslorient -swaporient ${MNI}_flip

  # flirt one to the other
  flirt -in ${MNI}_flip -ref ${MNI} -dof 12 -omat ${MNI}_flip.mat
  applywarp --rel --in=${MNI}_flip --ref=${MNI} --out=${MNI}_flip --premat=${MNI}_flip.mat --interp=spline
  fslmaths ${MNI}_flip -thr 0 ${MNI}_flip

  echo "  done"
fi


# create an corrected image based on the flipped image
if [[ $(getoption "corrflip" "$@") = "TRUE" ]] ; then
  # input:  ${MNI}, $flipimg, $roicorrflip
  # output: ${MNI}_corr
  echo "rough image correction based on $flipimg"

  # take the minimal value from the original and the flipped image
  fslmaths ${MNI} -min $flipimg ${MNI}_min

  # create smooth transitions from the original to the minimal image
  fslmaths ${MNI} -add 1 -bin -roi $roicorrflip -s 1 ${MNI}_ant_mask
  fslmaths ${MNI}_ant_mask -mul -1 -add 1 ${MNI}_post_mask

  # combine the original and minimal image
  fslmaths ${MNI} -mul ${MNI}_post_mask ${MNI}_post
  fslmaths ${MNI}_min -mul ${MNI}_ant_mask ${MNI}_ant
  fslmaths ${MNI}_post -add ${MNI}_ant -thr 0 ${MNI}_corr

  # clean up
  imrm ${MNI}_min ${MNI}_post_mask ${MNI}_ant_mask ${MNI}_post ${MNI}_ant

  echo "  done"
fi


# extract the brain
if [[ $(getoption "bet" "$@") = "TRUE" || $(getoption "betlib" "$@") = "TRUE" ]] ; then
  # input:  $betinput
  # output: ${MNI}_brain, ${MNI}_brain_mask, ${MNI}_brain_mask_strict
  echo "extract brain from $betinput"

  # find the number of voxels
  xdim=$(fslhd -x $betinput | grep "nx = " | tr -d "[:alpha:][:space:][:punct:]")
  ydim=$(fslhd -x $betinput | grep "ny = " | tr -d "[:alpha:][:space:][:punct:]")
  zdim=$(fslhd -x $betinput | grep "nz = " | tr -d "[:alpha:][:space:][:punct:]")
  # find sensible centroids to initialise bet
  xhalf=$(echo $xdim | awk '{print $1/2}')
  ypost=$(echo $ydim | awk '{print $1/3}')
  yhalf=$(echo $ydim | awk '{print $1/2}')
  yant=$(echo $ydim | awk '{print $1*2/3}')
  zhalf=$(echo $zdim | awk '{print $1/2}')

  # run bet centred at an anterior position
  bet $betinput ${MNI}_brain_ant -m -n -r 30 -f 0.5 -c $xhalf $yant $zhalf
  # and once more at a central (default) position
  bet $betinput ${MNI}_brain -m -n -r 30 -f 0.5 -c $xhalf $yhalf $zhalf
  # and once more at a posterior position
  bet $betinput ${MNI}_brain_post -m -n -r 30 -f 0.5 -c $xhalf $ypost $zhalf

  # add them and binarise
  fslmaths ${MNI}_brain_mask -add ${MNI}_brain_ant_mask -add ${MNI}_brain_post_mask -bin ${MNI}_brain_mask

  # find the extent of the brain mask
  str=$(fslstats ${MNI}_brain_mask -C -w)

  # if you want to exclude or include part of the olfactory bulb
  if [[ $(getoption "olfactbulb" "$@") = "TRUE" ]] ; then
    # extract coordinates for frontal pole centroid
    x=$(echo $str | awk '{print $1}')
    y=$(echo $str | awk '{print $2+$7*3/7}')
    z=$(echo $str | awk '{print $3}')

    # frontal pole bet
    bet $betinput ${MNI}_Fpole -m -n -r 20 -f 0.8 -c $x $y $z

  else
    # extract coordinates for frontal pole centroid
    x=$(echo $str | awk '{print $1}')
    y=$(echo $str | awk '{print $2+$7*3/8}') #255
    z=$(echo $str | awk '{print $3+$9/12}') #107

    # frontal pole bet
    bet $betinput ${MNI}_Fpole -m -r 25 -f 0.6 -c $x $y $z

    # erode, cluster, ignore olfactory bulb, and dilate
    thr=$(fslstats ${MNI}_Fpole -P 20)
    fslmaths ${MNI}_Fpole -thr $thr -bin -ero -ero ${MNI}_Fpole
    cluster --in=${MNI}_Fpole --thresh=0.5 --no_table --connectivity=6 --minextent=10000 --oindex=${MNI}_Fpole
    fslmaths ${MNI}_Fpole -bin -dilF -s 0.5 -thr 0.002 -bin ${MNI}_Fpole_mask
  fi

  # extract coordinates for temporal pole centroid
  xL=$(echo $str | awk '{print $1-$5*2/7}')
  xR=$(echo $str | awk '{print $1+$5*2/7}')
  y=$(echo $str | awk '{print $2+$7/6}')
  z=$(echo $str | awk '{print $3-$9*2/6}')

  # temporal poles bet
  bet $betinput ${MNI}_TpoleL -m -n -r 20 -f 0.5 -c $xL $y $z
  bet $betinput ${MNI}_TpoleR -m -n -r 20 -f 0.5 -c $xR $y $z

  # combine brain mask with all the poles
  fslmaths ${MNI}_brain_mask -add ${MNI}_Fpole_mask -add ${MNI}_TpoleL_mask -add ${MNI}_TpoleR_mask -bin ${MNI}_brain_mask
  fslmaths $betinput -mas ${MNI}_brain_mask ${MNI}_brain
  imcp ${MNI}_brain_mask ${MNI}_brain_mask_bet

  # find the largest bright cluster, and remove all other clusters
  thr=$(fslstats ${MNI}_brain -P 20)
  cluster --in=${MNI}_brain --thresh=$thr --no_table --connectivity=6 --minextent=10000 --oindex=${MNI}_brain_mask
  # fill holes, smooth with gaussion kernel to dilate
  fslmaths ${MNI}_brain_mask -bin -fillh -s 0.5 -thr 0.1 -bin -fillh -s 1 -thr 0.4 -bin -fillh ${MNI}_brain_mask

  if [[ $(getoption "betlib" "$@") = "TRUE" ]] ; then
    # do this again, but now at a more liberal threshold
    thr=$(fslstats ${MNI}_brain -P 10)
    cluster --in=${MNI}_brain --thresh=$thr --no_table --connectivity=6 --minextent=10000 --oindex=${MNI}_brain_mask_liberal
    # fill holes, smooth with gaussion kernel to dilate
    fslmaths ${MNI}_brain_mask_liberal -bin -fillh -s 0.5 -thr 0.3 -bin -fillh -s 1 -thr 0.4 -bin -fillh ${MNI}_brain_mask_liberal

    # combine these two, but exclude liberal areas with high intensity
    fslmaths ${MNI}_brain_mask_liberal -sub ${MNI}_brain_mask -bin ${MNI}_2remove
    fslmaths $betinput -mas ${MNI}_2remove ${MNI}_2remove
    cluster --in=${MNI}_2remove --thresh=0.5 --no_table --connectivity=6 --minextent=100 --omax=${MNI}_2remove_max --omean=${MNI}_2remove_mean --osize=${MNI}_2remove_size
    fslmaths ${MNI}_2remove_mean -thr 200 -bin -mul ${MNI}_2remove_max -thr 400 -bin ${MNI}_2remove
    fslmaths ${MNI}_brain_mask_liberal -add ${MNI}_brain_mask -bin -sub ${MNI}_2remove -bin -fillh ${MNI}_brain_mask

    # exclude bits with very low values
    thr=$(fslstats $betinput -k ${MNI}_brain_mask -p 0.2)
    # fslmaths $betinput -thr $thr -mas ${MNI}_brain_mask -bin ${MNI}_brain_mask
    extrmthr=$(echo $thr | awk '{print $1*10}')
    newthr=$(echo $extrmthr $thr | awk '{print $1-$2}')
    fslmaths $betinput -sub $extrmthr -mas ${MNI}_brain_mask -mul -1 ${MNI}_2remove
    cluster --in=${MNI}_2remove --thresh=$newthr --no_table --omax=${MNI}_2remove
    newthr=$(echo $extrmthr $thr | awk '{print $1-$2/5}')
    fslmaths ${MNI}_2remove -thr $newthr -bin ${MNI}_2remove
    fslmaths ${MNI}_brain_mask -sub ${MNI}_2remove -bin -fillh ${MNI}_brain_mask
  fi

  # if you want to exclude the olfactory bulb
  if [[ $(getoption "olfactbulb" "$@") != "TRUE" ]] ; then
    fslmaths ${MNI}_brain_mask -sub ${MNI}_brain_mask_bet -bin -add ${MNI}_Fpole_mask -add ${MNI}_Fpole_mask ${MNI}_2remove
    cluster --in=${MNI}_2remove --thresh=0.5 --no_table --connectivity=6 --minextent=100 --omax=${MNI}_2remove
    fslmaths ${MNI}_2remove -thr 1.5 -bin -sub ${MNI}_Fpole_mask -bin ${MNI}_2remove
    fslmaths ${MNI}_brain_mask -sub ${MNI}_2remove -fillh ${MNI}_brain_mask
  fi

  # extract the brain
  fslmaths $betinput -mas ${MNI}_brain_mask ${MNI}_brain

  # and make a strict mask
  thr=$(fslstats ${MNI}_brain -P 5)
  cluster --in=${MNI}_brain --thresh=$thr --no_table --connectivity=6 --minextent=10000 --oindex=${MNI}_brain_mask_strict
  fslmaths ${MNI}_brain_mask_strict -bin -fillh -s 0.5 -thr 0.5 -bin -mas ${MNI}_brain_mask -fillh ${MNI}_brain_mask_strict

  # clean up
  imrm ${MNI}_brain_ant_mask ${MNI}_brain_post_mask ${MNI}_Fpole ${MNI}_Fpole_mask ${MNI}_TpoleL_mask ${MNI}_TpoleR_mask ${MNI}_brain_mask_bet ${MNI}_brain_mask_liberal ${MNI}_2remove*

  echo "  done"
fi


# flipnonlin
if [[ $(getoption "flipnonlin" "$@") = "TRUE" ]] ; then
  # input:  ${MNI}, ${MNI}_corr, ${MNI}_brain_mask, ${MNI}_fliplin.mat
  # output: ${MNI}_flip
  echo "non-linear register the flipped image, ignoring bright spots"

  # create a halo running outwards and inwards from the edge of the brain mask
  fslmaths ${MNI}_brain_mask -sub 0.5 -s 2 -uthr 0 -mul 2 -add 1 ${MNI}_brain_halo_out
  fslmaths ${MNI}_brain_mask -sub 0.5 -s 2 -thr 0 -mul -2 -add 1 ${MNI}_brain_halo_in
  fslmaths ${MNI}_brain_halo_out -mul ${MNI}_brain_halo_in ${MNI}_brain_halo

  # create a halo weighted mask that ignores places of big difference
  fslmaths ${MNI} -sub ${MNI}_corr -mul ${MNI}_brain_halo -thr 100 -binv -ero ${MNI}_fnirt_mask
  imcp ${MNI}_fnirt_mask ${MNI}_fnirt_mask_flip
  fslorient -swaporient ${MNI}_fnirt_mask_flip

  # copy the image and mask
  imcp ${MNI} ${MNI}_flip
  # swap left-right
  fslorient -swaporient ${MNI}_flip

  # fnirt one to the other
  fnirt --ref=${MNI} --refmask=${MNI}_fnirt_mask --in=${MNI}_flip --inmask=${MNI}_fnirt_mask_flip --aff=${MNI}_flip.mat --fout=${MNI}_flip_warp --config=$config

  # use spline interpolation to apply the warp field
  applywarp --rel --interp=spline -i ${MNI}_flip -r ${MNI} -w ${MNI}_flip_warp -o ${MNI}_flip
  fslmaths ${MNI}_flip -thr 0 ${MNI}_flip

  # clean up
  imrm ${MNI}_brain_halo_out ${MNI}_brain_halo_in ${MNI}_brain_halo ${MNI}_fnirt_mask ${MNI}_fnirt_mask_flip

  echo "  done"
fi


# correct too bright CSF
if [[ $(getoption "corrCSF" "$@") = "TRUE" ]] ; then
  # input:  ${MNI}_corr, ${MNI}_brain_mask, ${MNI}_brain_mask_strict, $roicorrCSF
  # output: ${MNI}_corr, ${MNI}_brain
  echo "correct bright CSF around brain"

  # segment the regular mask to create an alternative strict brain mask
  fslmaths ${MNI}_corr -mas ${MNI}_brain_mask ${MNI}_brain
  fast -n 3 -l 8 -t 1 -N -p -o ${MNI}_segment ${MNI}_brain
  fslmaths ${MNI}_segment_prob_1 -add ${MNI}_segment_prob_2 -thr 0.00001 -bin -fillh ${MNI}_segment_mask
  cluster --in=${MNI}_segment_mask --thresh=0.5 --no_table --connectivity=6 --minextent=10000 --oindex=${MNI}_segment_mask
  fslmaths ${MNI}_segment_mask -bin -s 1 -thr 0.3 -bin -fillh -mas ${MNI}_brain_mask_strict ${MNI}_segment_mask

  # find orbitofrontal spots that exceed the alternative mask
  fslmaths ${MNI}_brain_mask_strict -roi $roicorrCSF -sub ${MNI}_segment_mask -bin ${MNI}_brightCSF_mask
  cluster --in=${MNI}_brightCSF_mask --thresh=0.5 --no_table --minextent=5 --connectivity=26 --oindex=${MNI}_brightCSF_mask
  fslmaths ${MNI}_brightCSF_mask -bin -dilF -sub ${MNI}_segment_mask -bin -s 0.25 -mul -1 -add 1 ${MNI}_corr_weight

  # find baseline CSF intensity
  fslmaths ${MNI}_brain_mask -sub ${MNI}_segment_mask -bin ${MNI}_CSF
  baseline=$(fslstats ${MNI}_brain -k ${MNI}_CSF -m)

  # normalise bright CSF to baseline values
  fslmaths ${MNI}_corr -sub $baseline -mul ${MNI}_corr_weight -add $baseline -thr 0 ${MNI}_corr
  fslmaths ${MNI}_corr -mas ${MNI}_brain_mask ${MNI}_brain

  # clean up
  imrm ${MNI}_segment* ${MNI}_brightCSF_mask ${MNI}_CSF ${MNI}_corr_weight

  echo "  done"
fi


# correct edges and bright spots
if [[ $(getoption "corrspots" "$@") = "TRUE" ]] ; then
  # input:  ${MNI}, ${MNI}_corr, ${MNI}_brain_mask, ${MNI}_brain_mask_strict
  # output: ${MNI}_corr, ${MNI}_brain
  echo "correct edges around brain, and bright spots inside"

  # find the difference between the original and the current working image
  fslmaths ${MNI} -sub ${MNI}_corr ${MNI}_diff

  # find suitable clusters inside the strict brain mask
  fslmaths ${MNI}_diff -mul ${MNI} -mas ${MNI}_brain_mask_strict -div 200 -div 200 ${MNI}_spots
  cluster --in=${MNI}_spots --thresh=0.6 --no_table --connectivity=6 --omax=${MNI}_spots
  fslmaths ${MNI}_spots -thr 2 -bin ${MNI}_spots

  # now dilate that spots masks
  fslmaths ${MNI}_spots -dilF -fillh ${MNI}_spots

  # create an edge mask, and include the spots
  fslmaths ${MNI}_brain_mask -sub ${MNI}_brain_mask_strict -bin ${MNI}_edge_mask
  fslmaths ${MNI}_brain_mask_strict -dilF -sub ${MNI}_brain_mask_strict -bin -add ${MNI}_edge_mask -add ${MNI}_spots -bin ${MNI}_edge_mask

  # create a weighting halo from the edge of the brain mask
  fslmaths ${MNI}_edge_mask -fillh ${MNI}_edge_halo_out
  fslmaths ${MNI}_edge_halo_out -mul -1 -add 1 -add ${MNI}_edge_mask -bin ${MNI}_edge_halo_in
  fslmaths ${MNI}_edge_halo_out -s 2 -sub 0.5 -uthr 0 -mul 2 -add 1 ${MNI}_edge_halo_out
  fslmaths ${MNI}_edge_halo_in -s 2 -sub 0.5 -uthr 0 -mul 2 -add 1 ${MNI}_edge_halo_in
  fslmaths ${MNI}_edge_halo_out -mul ${MNI}_edge_halo_in ${MNI}_edge_halo
  fslmaths ${MNI}_edge_halo -mul -1 -add 1 ${MNI}_edge_halo_inv

  # use the weighting halo to combine the original and corrected images
  fslmaths ${MNI} -mul ${MNI}_edge_halo_inv ${MNI}_A
  fslmaths ${MNI}_corr -mul ${MNI}_edge_halo ${MNI}_B
  fslmaths ${MNI}_A -add ${MNI}_B -thr 0 ${MNI}_corr
  fslmaths ${MNI}_corr -mas ${MNI}_brain_mask ${MNI}_brain

  # clean up
  imrm ${MNI}_diff ${MNI}_spots ${MNI}_edge_mask ${MNI}_edge_halo_out ${MNI}_edge_halo_in ${MNI}_edge_halo ${MNI}_edge_halo_inv ${MNI}_A ${MNI}_B

  echo "  done"
fi


# down-sample the corrected image and masks
if [[ $(getoption "downsamp" "$@") = "TRUE" ]] ; then
  # input:  ${MNI}_corr, ${MNI}_brain_mask, ${MNI}_brain_mask_strict
  # output: ${MNI}_corr_05mm, ${MNI}_corr_1mm, etc
  echo "down-sampling image: ${MNI}_corr"

    # down-sample to 0.5 mm
    fslmaths ${MNI}_corr -subsamp2 -thr 0 ${MNI}_corr_05mm
    fslmaths ${MNI}_brain_mask -subsamp2 -thr 0.5 -bin ${MNI}_brain_mask_05mm
    fslmaths ${MNI}_brain_mask_strict -subsamp2 -thr 0.5 -bin ${MNI}_brain_mask_strict_05mm

    # down-sample to 1 mm
    fslmaths ${MNI}_corr -subsamp2 -subsamp2 -thr 0 ${MNI}_corr_1mm
    fslmaths ${MNI}_brain_mask -subsamp2 -subsamp2 -thr 0.5 -bin ${MNI}_brain_mask_1mm
    fslmaths ${MNI}_brain_mask_strict -subsamp2 -subsamp2 -thr 0.5 -bin ${MNI}_brain_mask_strict_1mm

  echo "  done"
fi


# bias correct the corrected image
if [[ $(getoption "biascorr" "$@") = "TRUE" ]] ; then
  # input:  ${MNI}_corr, ${MNI}_brain_mask_strict
  # output: ${MNI}_restore, ${MNI}_bias
  echo "bias correcting image: ${MNI}_corr"

  # ignore extreme values in strict brain mask
  thrlow=$(fslstats ${MNI}_corr -k ${MNI}_brain_mask_strict -p 5)
  thrhigh=$(fslstats ${MNI}_corr -k ${MNI}_brain_mask_strict -p 99.8)
  fslmaths ${MNI}_corr -mas ${MNI}_brain_mask_strict -thr $thrlow -uthr $thrhigh -bin ${MNI}_brain_mask_biascorr

  # smoothness definitions
  sigma=3
  FWHM=$(echo "2.3548 * $sigma" | bc)

  # run RobustBiasCorr
  $SD/RobustBiasCorr.sh \
    --in=${MNI}_corr \
    --workingdir=$WD/biascorr \
    --brainmask=${MNI}_brain_mask_biascorr \
    --basename=struct \
    --FWHM=$FWHM \
    --type=1 \
    --forcestrictbrainmask="FALSE" --ignorecsf="FALSE"

  # copy the restored image and bias field, and remove working directory
  imcp $WD/biascorr/struct_restore ${MNI}_restore
  imcp $WD/biascorr/struct_bias ${MNI}_bias
  rm -rf $WD/biascorr

  # extract the brain
  fslmaths ${MNI}_restore -mas ${MNI}_brain_mask ${MNI}_restore_brain

  # clean up
  imrm ${MNI}_brain_mask_biascorr

  echo "  done"
fi
