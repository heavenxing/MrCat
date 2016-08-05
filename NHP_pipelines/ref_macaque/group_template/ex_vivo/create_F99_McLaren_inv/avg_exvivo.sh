#!/usr/bin/env bash
set -e    # stop immediately on error
umask u+rw,g+rw # give group read/write permissions to all new files

# average some ex-vivo templates

# ------------------------------ #
# usage
# ------------------------------ #

usage() {
cat <<EOF

Average ex-vivo templates
example:
      $(basename $0) --subjlist="oddie@hilary@umberto"

usage: $(basename $0)
      [--subjlist=<list of subjects>] (default: oddie@hilary@umberto)

EOF
}


# ------------------------------ #
# overhead
# ------------------------------ #

# if help is requested, return the usage
if [[ $@ =~ --help ]] ; then usage; exit 0; fi

# set defaults
subjList="umberto hilary oddie"

# parse the input arguments
for a in "$@" ; do
  case $a in
    -s=*|--subj=*|--subjlist=*) subjList="${a#*=}"; shift ;;
  esac
done
subjList="${subjList//@/ }"


# loop over monkeys
cmdExVivo=""
cmdMcLaren=""
c=0
for monkey in $subjList ; do

  # define image to average
  imgExVivo=$MRCATDIR/ref_macaque/proc/ex_vivo_template/$monkey/T1w_restore_F99
  imgMcLaren=$MRCATDIR/ref_macaque/proc/ex_vivo_template/$monkey/McLaren_inv

  # construct command strings
  [[ -z $cmdExVivo ]] && cmdExVivo=$imgExVivo || cmdExVivo="$cmdExVivo -add $imgExVivo"
  [[ -z $cmdMcLaren ]] && cmdMcLaren=$imgMcLaren || cmdMcLaren="$cmdMcLaren -add $imgMcLaren"
  ((++c))

done

fslmaths $cmdExVivo -div $c $MRCATDIR/ref_macaque/proc/ex_vivo_template/avg_exvivo
fslmaths $cmdMcLaren -div $c $MRCATDIR/ref_macaque/proc/ex_vivo_template/avg_McLaren_inv
