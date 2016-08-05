#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# This is template script for a simple fixed processing pipeline


# ------------------------------ #
# Help
# ------------------------------ #

usage() {
cat <<EOF

reorient.sh: Reorient an image according to macaque standard

example:
      sh reorient.sh image.nii.gz

usage: $(basename $0)
      obligatory arguments
        <input image> : the input image to process

EOF
}


# ------------------------------ #
# Housekeeping
# ------------------------------ #
# if no arguments given, or help is requested, return the usage
if [[ $# -eq 0 ]] || [[ $@ =~ --help ]] ; then usage; exit 0; fi

# if too few arguments given, return the usage, exit with error
if [[ $# -lt 1 ]] ; then >&2 usage; exit 1; fi

# set defaults

# parse the input arguments
for a in "$@" ; do
  case $a in
    #-s=*|--setting=*)   setting="${a#*=}"; shift ;;
    #-o=*|--option=*)    option="${a#*=}"; shift ;;
    *)                  arg="$arg $a"; shift ;; # ordered arguments
  esac
done

# parse for obligatory arguments
# extract arguments that don't start with "-"
argobl=$(echo $arg | tr " " "\n" | grep -v '^-') || true
# parse obligatory arguments from the non-dash arguments
img=$(echo $argobl | awk '{print $1}')

# check if obligatory arguments have been set
if [[ -z $img ]] ; then
  >&2 echo ""; >&2 echo "error: please specify the input image."
  usage; exit 1
fi

# remove img and base from list of arguments
arg=$(echo $arg | tr " " "\n" | grep -v "$img") || true

# check if no redundant arguments have been set
if [[ -n $arg ]] ; then
  >&2 echo ""; >&2 echo "unsupported arguments are given:" $arg
  usage; exit 1
fi


# ------------------------------ #
# Do the work
# ------------------------------ #

fslorient -deleteorient $img
fslorient -setqformcode 1 $img
fslorient -forceradiological $img
