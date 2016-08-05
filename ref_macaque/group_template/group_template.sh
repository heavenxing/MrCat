#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# Making an ex-vivo reference template image


# ------------------------------ #
# usage
# ------------------------------ #

usage() {
cat <<EOF

Create a group template from a set of source images, registered to a reference
image. Please ensure that the source images are already bias-corrected. You can
specify the full path of the source images in a list, or specify base names
e.g. subject names) if your data is stored: <workdir>/source/<base>/<sourceimg>

example:
      $(basename $0) --workdir=$(pwd) --sourcelist=image1@image2 --source2ref

usage: $(basename $0)
  obligatory arguments:
      --source=<list of source images> : this could be a single image, or
          a "@"-separated list of images that act as a source for the
          registration and creation of a new group template
      --ref=<reference image> : the new group template will be registered to
          this reference image
  optional arguments:
      [--workdir=<working directory>] : this will be the main directory where
          the script will be run, the logfiles will be written, and the results
          will be stored. Sub directories will be created automatically
          (default: $(pwd))
      [--base=<list of base-names for source and output (subject name)>] :
          a "@"-separated list matching the source; if a single source image is
          specified with a list of base names, then the base is interpreted as a
          list of source sub-directories: <workdir>/source/<base>/<sourceimg>
          (default: <extracted from source image>)
      [--sourcemask=<list of source brain masks>] : a "@"-separated list of
          brain masks matching the source images
          (default: <source image>_brain_mask)
      [--refmask=<list of reference brain masks>] : a brain mask matching the
          reference image (default: <ref image>_brain_mask)
      [--flirtOptions=<extra options for flirt>] (default: none)
      [--iteration=<iteration number/label>] state the number (or label) of the
          current iteration. If you do not want to postpad your transformation
          with the iteration, please explicitely state it to be empty (""),
          otherwise it will try to auto-detect the current iteration.
          (default for --source2ref: initial)
          (otherwise: inferred from previteration or <workdir>/transform)
      [--previteration=<previous iteration>] state the number (or label) of the
          previous iteration. If you do not want to postpad your transformation
          with the iteration, please explicitely state it to be empty (""),
          otherwise it will try to auto-detect the previous iteration.
          (default for --source2ref: none)
          (otherwise: <current iteration> - 1)
      [--configdir=<directory with fnirt configuration files>]
          (default: <workdir>/config)
      [--config=<config file>] (default: <configdir>/config_<iteration>.cnf)
  optional instructions:
      [--all] : execute all instructions --source2ref
      [--source2ref] : first registration of source images to reference
      [--groupavg] : average registered source images to create a group template
      [--group2ref] : register group template to reference
      [--source2group] : register the source images to the group template

EOF
}


# ------------------------------ #
# overhead
# ------------------------------ #

# if no arguments given, return the usage
if [[ $# -eq 0 ]] || [[ $@ =~ --help ]] ; then usage; exit 0; fi

# if too few arguments given, return the usage, exit with error
if [[ $# -lt 1 ]] ; then >&2 usage; exit 1; fi

# if directory of this scirpt is not given, retrieve it
[[ $0 == */* ]] && thisScript=$0 || thisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/$0
scriptDir=$(dirname $thisScript)

# if no input or "--all" is given, run the default set
defaultSet="--source2ref"
if [[ $# -eq 0 ]] || [[ "$@" =~ --all ]] ; then
  echo "running the complete set of instructions: $defaultSet"
  # execute this script with the default argument set, and passing others
  [[ $# -eq 0 ]] && newArg=$defaultSet || newArg=$(echo "${@//--all/$defaultSet}")
  sh $thisScript $newArg
  exit 0
fi

# run each instruction on its own (with the same definitions)
definitionargs=$(echo "$@" | tr " " "\n" | grep '=') || true
instructargs=$(echo "$@" | tr " " "\n" | grep -v '=') || true
if [[ $(echo "$instructargs" | wc -w) -gt 1 ]] ; then
  # this ensures the instructions are executed as specified, not as coded below
  for instr in $instructargs ; do
    sh $thisScript $definitionargs $instr
  done
  exit 0
fi

# count and grep the number of argument repetitions (ignoring after "=")
duplicates=$(echo "$@" | tr " " "\n" | awk '{ gsub("=.*","="); print $0}' | sort | uniq -c | grep -v '^ *1 ') || true   # "|| true" is added to ignore the non-zero exit code of grep (and avoid the script the stop because of "set -e")
# now test if any duplicates were found, and if so, give an error
[[ -n $duplicates ]] && echo "\nError, repetitions found in the arguments:\n$@\n${duplicates}\n" && exit 1


# ------------------------------ #
# definitions and settings
# ------------------------------ #

# MrCat directory
if [[ -z $MRCATDIR ]] ; then
  [[ $OSTYPE == darwin* ]] && export MRCATDIR=$HOME/code/MrCat-dev
  [[ $OSTYPE == linux-gnu ]] && export MRCATDIR=$HOME/scratch/MrCat-dev
fi

# set defaults
instr=""
arg=""
workDir=$(pwd)
flirtOptions=""
iCurr="auto"
iPrev="auto"

# parse the input arguments
for a in "$@" ; do
  case $a in
    -w=*|--work=*|--workdir=*)                    workDir="${a#*=}"; shift ;;
    -s=*|--source=*|--sourceimg=*|--sourcelist=*) sourceImgList="${a#*=}"; shift ;;
    --sourcemask=*|--sourcemasklist=*)            sourceMaskList="${a#*=}"; shift ;;
    --base=*|--sourcebase=*|--baselist=*|--sourcebaselist=*)  sourceBaseList="${a#*=}"; shift ;;
    -r=*|--ref=*|--refimg=*)                      refImg="${a#*=}"; shift ;;
    --refmask=*)                                  refMask="${a#*=}"; shift ;;
    --flirtoptions=*)                             flirtOptions="${a#*=}"; shift ;;
    --config=*)                                   configCurr"${a#*=}"; shift ;;
    --configdir=*)                                configDir="${a#*=}"; shift ;;
    --i=*|--c=*|--iteration=*)                    iCurr="${a#*=}"; shift ;;
    --p=*|--previteration=*)                      iPrev="${a#*=}"; shift ;;
    --*)                                          instr="$instr $a"; shift ;; # instruction argument
    *)                                            arg="$arg $a"; shift ;; # unsupported argument
  esac
done

# check that obligatory arguments are set
[[ -z $sourceImgList ]] && >&2 echo "please specify at least one source image"

# check if no redundant arguments have been set
if [[ -n $arg ]] ; then
  >&2 echo ""; >&2 echo "unsupported arguments are given:" $arg
  usage; exit 1
fi

# replace "@" by spaces to create loop-able lists
sourceImgList="${sourceImgList//@/ }"
sourceMaskList="${sourceMaskList//@/ }"
sourceBaseList="${sourceBaseList//@/ }"
# remove extension
sourceImgList=$(remove_ext $sourceImgList) || true
sourceMaskList=$(remove_ext $sourceMaskList) || true
refImg=$(remove_ext $refImg) || true
refMask=$(remove_ext $refMask) || true
refBase=$(basename $refImg)
refSpace=$(echo $refImg | awk 'BEGIN {FS="/"} {print $(NF-1)}')
[[ $refBase != $refSpace ]] && refBase=${refSpace}_$refBase

# match the sourceBaseList with the sourceImgList
if [[ -z $sourceBaseList ]] ; then
  # if no sourceBaseList is specified, obtain base names from the sourcelist
  nBase=$(basename $sourceImgList | sort | uniq | wc -l)
  # if each source has a unique name, the source is also used as a base
  if [[ $nBase -eq $(echo $sourceImgList | wc -w) ]] ; then
    sourceBaseList=$(basename $sourceImgList)
    sourceBaseList=$(echo $sourceBaseList)
  else
    # extract the last directory from the sourceImgList
    sourceBaseList=$(echo $sourceImgList | tr " " "\n" | awk 'BEGIN {FS="/"} {print $(NF-1)}')
    # test if the number of unique entries matches the sourceImgList
    nBase=$(basename $sourceBaseList | sort | uniq | wc -l)
    if [[ $nBase -ne $(echo $sourceImgList | wc -w) ]] ; then
      >&2 echo "Base names could not be easily extracted from the source image file names."
      >&2 echo "Please explicitely provide basenames in the --base=<list> argument."
      exit 1
    fi
    sourceBaseList=$(echo $sourceBaseList)
  fi

elif [[ $(echo $sourceImgList | wc -w) -eq 1 ]] && [[ $(echo $sourceBaseList | wc -w) -gt 1 ]] ; then
  # the baselist is interpreted as a list of subject directories, with the same
  # source name appended
  sourceImgList=$(echo $sourceBaseList | tr " " "\n" | awk '{print "'$workDir'/source/"$1"/'$sourceImgList'"}')
  sourceImgList=$(echo $sourceImgList)

elif [[ $(echo $sourceImgList | wc -w) -ne $(echo $sourceBaseList | wc -w) ]] ; then
  # the number of items in the base and source lists do not match
  >&2 echo "The number of items in the --base and --source lists do not match"
  exit 1
fi

# set input dependent defaults
[[ -z $sourceMaskList ]] && sourceMaskList=$(echo $sourceImgList | tr " " "\n" | awk '{print $1"_brain_mask"}')
sourceMaskList=$(echo $sourceMaskList)
[[ -z $configDir ]] && configDir=$workDir/config
[[ -n $config ]] && configDir=$(dirname $config)

# auto-detect current and previous iteration
[[ $iCurr == auto ]] && [[ $instr =~ --source2ref$ ]] && iCurr="initial"
if [[ $iCurr == auto ]] ; then
  case $iPrev in
    auto)       # list directories in the transform directory
                iPrev=$(find $workDir/transform/* -prune -type d)
                iPrev=$(basename $iPrev | grep '^[0-9][0-9]*$' | sort -n | tail -n 1)
                [[ -z $iPrev ]] && >&2 echo "The current iteration could not be inferred from $workDir/transform, please specify explicitely in --iteration" && exit 1
                iCurr=$((iPrev+1))
                ;;
    initial)    iCurr=1 ;;
    *[!0-9]*)   >&2 echo "The current iteration could not be inferred from --previteration, please specify explicitely in --iteration" ; exit 1 ;;
    *)          iCurr=$((iPrev+1))
  esac
fi
if [[ $iPrev == auto ]] ; then
  case $iCurr in
    initial)    iPrev="none" ;;
    *[!0-9]*)   >&2 echo "The previous iteration could not be inferred from --iteration, please specify explicitely in --previteration" ; exit 1 ;;
    1)          iPrev=initial ;;
    *)          iPrev=$((iCurr-1)) ;;
  esac
fi

# add leading underscores
[[ -n $iCurr ]] && [[ ! $iCurr =~ ^_ ]] && iCurr=_$iCurr
[[ -n $iPrev ]] && [[ ! $iPrev =~ ^_ ]] && iPrev=_$iPrev

# specify fnirt config file
[[ -z $config ]] && config=$configDir/config$iCurr

# make the working directory
mkdir -p $workDir; workDir=$(cd $workDir && pwd)

# specify and make the subfolders
logDir=$workDir/log; mkdir -p $logDir
refDir=$workDir/$refBase; mkdir -p $refDir
groupDir=$workDir/group; mkdir -p $groupDir
sourceDir=$workDir/source; mkdir -p $sourceDir
transDir=$workDir/transform; mkdir -p $transDir


# ------------------------------ #
# the instructions are coded below
# ------------------------------ #

# register source images to reference template
if [[ $instr =~ --source2ref$ ]] ; then
  echo "register structural to reference template"

  # transform sub-folder
  [[ -n $iCurr ]] && transDir=$transDir/${iCurr/_/} && mkdir -p $transDir

  # loop over source images
  c=1
  for sourceBase in $sourceBaseList ; do
    echo "  source: $sourceBase"
    # retrieve image and mask accompanying current source
    sourceImg=$(echo $sourceImgList | awk '{print $'$c'}')
    sourceMask=$(echo $sourceMaskList | awk '{print $'$c'}') # only used for linear registration

    # make source image specific directory
    mkdir -p $sourceDir/$sourceBase

    # perform linear registration of the structural to reference
    echo "  linear registration"
    flirt -dof 12 -ref $refImg -refweight $refMask -in $sourceImg -inweight $sourceMask -omat $transDir/${sourceBase}_to_${refBase}.mat $flirtOptions

    # check cost of this registration
    cost=$(flirt -ref $refImg -in $sourceImg -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $transDir/${sourceBase}_to_${refBase}.mat | head -1 | cut -d' ' -f1)

    # decide if flirt is good enough or needs another try
    if [[ $(echo $cost | awk '($1>0.9){print 1}') ]] ; then
      echo "  registration is poor: the cost is $cost"
      echo "  for reference, a value of 0.8 or lower would be nice"
      echo "  rerunning linear registration with restricted search"

      # see if the original flirt was run without search
      if [[ $flirtOptions =~ -nosearch ]] ; then
        # remove the -nosearch option, but use a restricted schedule (simple3D)
        flirt -dof 12 -ref $refImg -refweight $refMask -in $sourceImg -inweight $sourceMask -omat $transDir/${sourceBase}_to_${refBase}_restricted.mat -schedule $FSLDIR/etc/flirtsch/simple3D.sch ${flirtOptions//-nosearch/}
      else
        # run flirt without search
        flirt -dof 12 -ref $refImg -refweight $refMask -in $sourceImg -inweight $sourceMask -omat $transDir/${sourceBase}_to_${refBase}_restricted.mat -nosearch $flirtOptions
      fi

      # calculate cost of restricted registration
      costRestr=$(flirt -ref $refImg -in $sourceImg -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $transDir/${sourceBase}_to_${refBase}_restricted.mat | head -1 | cut -d' ' -f1)

      # check if the new registration is actually better
      echo "  restricted registration cost is $costRestr"
      if [[ $(echo $cost $costRestr | awk '($1<$2){print 1}') ]] ; then
        # reject new registration
        echo "  keeping original registration, but please be warned of poor results"
        rm -rf $transDir/${sourceBase}_to_${refBase}_restricted.mat
      else
        if [[ $(echo $costRestr | awk '($1>0.9){print 1}') ]] ; then
          echo "  continuing, but please be warned of poor registration results"
        else
          echo "  restricted registration is accepted"
        fi
        # use new registration
        mv -f $transDir/${sourceBase}_to_${refBase}_restricted.mat $transDir/${sourceBase}_to_${refBase}.mat
      fi

    else
      echo "  the linear registration cost is $cost"
    fi

    # invert linear transformation
    #convert_xfm -omat $transDir/${refBase}_to_${sourceBase}.mat -inverse $transDir/${sourceBase}_to_${refBase}.mat

    # use spline interpolation to apply the linear transformation matrix
    applywarp --rel --interp=nn -i $sourceMask -r $refImg --premat=$transDir/${sourceBase}_to_${refBase}.mat -o $refDir/${sourceBase}_brain_mask_lin
    applywarp --rel --interp=spline -i $sourceImg -r $refImg -m $refDir/${sourceBase}_brain_mask_lin --premat=$transDir/${sourceBase}_to_${refBase}.mat -o $refDir/${sourceBase}_lin
    fslmaths $refDir/${sourceBase}_lin -thr 0 $refDir/${sourceBase}_lin
    #applywarp --rel --interp=nn -i $refMask -r $sourceImg --premat=$transDir/${refBase}_to_${sourceBase}.mat -o $sourceDir/$sourceBase/brainmask_${refBase}_lin

    # now preform non-linear registration
    echo "  non-linear registration"
    fnirt --ref=$refImg --refmask=$refMask --in=$sourceImg --aff=$transDir/${sourceBase}_to_${refBase}.mat --cout=$transDir/${sourceBase}_to_${refBase}_warpcoef --intout=$transDir/${sourceBase}_to_${refBase}_int --config=$config

    # copy the warpcoef, as if they were created by registering to a group template
    imcp $transDir/${sourceBase}_to_${refBase}_warpcoef $transDir/${sourceBase}_to_groupavg_warpcoef

    # use spline interpolation to apply the warp field
    echo "  applying the warp coefficients"
    applywarp --rel --interp=nn -i $sourceMask -r $refImg -w $transDir/${sourceBase}_to_${refBase}_warpcoef -o $refDir/${sourceBase}_brain_mask
    applywarp --rel --interp=spline -i $sourceImg -r $refImg -m $refDir/${sourceBase}_brain_mask -w $transDir/${sourceBase}_to_${refBase}_warpcoef -o $refDir/$sourceBase
    fslmaths $refDir/$sourceBase -thr 0 $refDir/$sourceBase

    # invert the warp field
    #invwarp --rel -w $transDir/${sourceBase}_to_${refBase}_warpcoef -o $transDir/${refBase}_to_${sourceBase}_warpfield -r $sourceImg
    #applywarp --rel --interp=nn -i $refMask -r $sourceImg -w $transDir/${refBase}_to_${sourceBase}_warpfield -o $sourceDir/$sourceBase/brainmask_${refBase}

    # move the log
    mv -f ${sourceImg}_to_"$(basename $refImg)".log $logDir/${sourceBase}_to_$refBase$iCurr.log

  done
  echo "  done"
fi


# average registered source images to create a group template
if [[ $instr =~ --groupavg$ ]] ; then
  echo "average registered source images to create a group template"

  # aggregate registered source images and masks
  cmdImg=""
  cmdMask=""
  c=0
  for sourceBase in $sourceBaseList ; do
    [[ -z $cmdImg ]] && cmdImg=$refDir/$sourceBase || cmdImg="$cmdImg -add $refDir/$sourceBase"
    [[ -z $cmdMask ]] && cmdMask=$refDir/${sourceBase}_brain_mask || cmdMask="$cmdMask -add $refDir/${sourceBase}_brain_mask"
    ((++c))
  done

  # average images and masks
  fslmaths $cmdImg -div $c $groupDir/groupavg$iCurr
  fslmaths $cmdMask -div $c $groupDir/groupavg_brain_mask$iCurr
  [[ -n $iCurr ]] && imcp $groupDir/groupavg$iCurr $groupDir/groupavg && imcp $groupDir/groupavg_brain_mask$iCurr $groupDir/groupavg_brain_mask

  echo "  done"
fi


# register group template to reference
if [[ $instr =~ --group2ref$ ]] ; then
  echo "register group template to reference"

  # specify current and previous transformation directories
  [[ -n $iPrev ]] && transPrevDir=$transDir/${iPrev/_/} || transPrevDir=$transDir
  [[ -n $iCurr ]] && transDir=$transDir/${iCurr/_/} && mkdir -p $transDir

  # specify reference and group
  groupImg=$groupDir/groupavg
  groupMask=$groupDir/groupavg_brain_mask # not used for non-linear registration

  # specify previous registration results
  warpPrev=$transPrevDir/groupavg_to_${refBase}_warpcoef
  intPrev=$transPrevDir/groupavg_to_${refBase}_int

  # non-linear registration
  if [[ -r $warpPrev.nii.gz ]] && [[ -r $intPrev.nii.gz ]] ; then
    fnirt --ref=$refImg --refmask=$refMask --in=$groupImg --inwarp=$warpPrev --intin=$intPrev --cout=$transDir/groupavg_to_${refBase}_warpcoef --intout=$transDir/groupavg_to_${refBase}_int --config=$config
  else
    fnirt --ref=$refImg --refmask=$refMask --in=$groupImg --cout=$transDir/groupavg_to_${refBase}_warpcoef --intout=$transDir/groupavg_to_${refBase}_int --config=$config
  fi

  # move the log
  mv -f ${groupImg}_to_"$(basename $refImg)".log $logDir/${groupImg}_to_"$(basename $refImg)"$iCurr.log

  # update the source_to_ref warp coefficients, and resample the source images
  cmdImg=""
  cmdMask=""
  c=1
  for sourceBase in $sourceBaseList ; do
    # retrieve image and mask accompanying current source
    sourceImg=$(echo $sourceImgList | awk '{print $'$c'}')
    sourceMask=$(echo $sourceMaskList | awk '{print $'$c'}') # not used for registration estimation

    # concatenating warps: please note that convertwarp does not output warp coefficients, but a field
    convertwarp --rel --relout --ref=$refImg --warp1=$transDir/${sourceBase}_to_groupavg_warpcoef --warp2=$transDir/groupavg_to_${refBase}_warpcoef --out=$transDir/${sourceBase}_to_groupavg_to_${refBase}_warpfield
    # applying new warp to resample source images
    applywarp --rel --interp=nn -i $sourceMask -r $refImg -w $transDir/${sourceBase}_to_groupavg_to_${refBase}_warpfield -o $refDir/${sourceBase}_brain_mask
    applywarp --rel --interp=spline -i $sourceImg -r $refImg -m $refDir/${sourceBase}_brain_mask -w $transDir/${sourceBase}_to_groupavg_to_${refBase}_warpfield -o $refDir/$sourceBase

    fslmaths $refDir/$sourceBase -thr 0 $refDir/$sourceBase

    # aggregate registered source images and masks
    [[ -z $cmdImg ]] && cmdImg=$refDir/$sourceBase || cmdImg="$cmdImg -add $refDir/$sourceBase"
    [[ -z $cmdMask ]] && cmdMask=$refDir/${sourceBase}_brain_mask || cmdMask="$cmdMask -add $refDir/${sourceBase}_brain_mask"
    ((++c))
  done

  # average images and masks
  ((--c))
  fslmaths $cmdImg -div $c $groupDir/groupavg$iCurr
  fslmaths $cmdMask -div $c $groupDir/groupavg_brain_mask$iCurr
  [[ -n $iCurr ]] && imcp $groupDir/groupavg$iCurr $groupDir/groupavg && imcp $groupDir/groupavg_brain_mask$iCurr $groupDir/groupavg_brain_mask

  echo "  done"
fi


# register source images to the group template
if [[ $instr =~ --source2group$ ]] ; then
  echo "register source images to the group template"

  # specify current and previous transformation directories
  [[ -n $iPrev ]] && transPrevDir=$transDir/${iPrev/_/} || transPrevDir=$transDir
  [[ -n $iCurr ]] && transDir=$transDir/${iCurr/_/} && mkdir -p $transDir

  # specify group template
  groupImg=$groupDir/groupavg
  groupMask=$groupDir/groupavg_brain_mask

  # loop over source images
  c=1
  for sourceBase in $sourceBaseList ; do
    echo "  source: $sourceBase"
    mkdir -p $sourceDir/$sourceBase
    # retrieve image and mask accompanying current source
    sourceImg=$(echo $sourceImgList | awk '{print $'$c'}')
    sourceMask=$(echo $sourceMaskList | awk '{print $'$c'}') # not used for registration estimation

    # specify previous registration results
    warpPrev=$transPrevDir/${sourceBase}_to_groupavg_to_${refBase}_warpfield
    [[ ! -r $warpPrev.nii.gz ]] && warpPrev=$transPrevDir/${sourceBase}_to_groupavg_warpcoef
    # please note that if you take the adjusted warpfield (source_to_group_to_ref)
    # then the intensity mapping does not perfectly match the warp...
    # I don't know how to solve this.
    # specify the previous intensity mapping
    intPrev=$transPrevDir/${sourceBase}_to_groupavg_int

    # non-linear registration
    if [[ -r $warpPrev.nii.gz ]] && [[ -r $intPrev.nii.gz ]] ; then
      fnirt --ref=$groupImg --refmask=$groupMask --in=$sourceImg --inwarp=$warpPrev --intin=$intPrev --cout=$transDir/${sourceBase}_to_groupavg_warpcoef --intout=$transDir/${sourceBase}_to_groupavg_int --config=$config
    else
      fnirt --ref=$groupImg --refmask=$groupMask --in=$sourceImg --cout=$transDir/${sourceBase}_to_groupavg_warpcoef --intout=$transDir/${sourceBase}_to_groupavg_int --config=$config
    fi

    # use spline interpolation to apply the warp field
    echo "  applying the warpcoef"
    applywarp --rel --interp=nn -i $sourceMask -r $groupImg -w $transDir/${sourceBase}_to_groupavg_warpcoef -o $refDir/${sourceBase}_brain_mask
    applywarp --rel --interp=spline -i $sourceImg -r $groupImg -m $refDir/${sourceBase}_brain_mask -w $transDir/${sourceBase}_to_groupavg_warpcoef -o $refDir/$sourceBase
    fslmaths $refDir/$sourceBase -thr 0 $refDir/$sourceBase

    # invert the warp field
    #invwarp -w $transDir/${sourceBase}_to_groupavg_warpcoef -o $transDir/groupavg_to_${sourceBase}_warpfield -r $sourceImg
    #applywarp --rel --interp=nn -i $refMask -r $sourceImg -w $transDir/groupavg_to_${sourceBase}_warpfield -o $sourceDir/$sourceBase/brainmask_groupavg

    # move the log
    mv -f ${sourceImg}_to_"$(basename $groupImg)".log $logDir/${sourceBase}_to_groupavg$iCurr.log

  done

  echo "  done"
fi
