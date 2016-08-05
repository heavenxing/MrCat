#!/bin/sh
#
# Simple script to make a new average
#

if [ "$#" -lt 2 ]
then
  echo Usage: 
  echo $0 inname outname
  echo or
  echo $0 inname outname basedir
  exit 1
fi
basedir="/Users/jesper/data/fnirt/JillsMonkeys/monkeys"
inname=$1
outname=$2
if [ "$#" -gt 2 ]
then
  basedir=$3
fi
tmpname=`mktemp /tmp/tmpima.XXXXXXXXXX`
if [ `imtest $outname` -eq 1 ]
then
  immv $outname ${outname}_old
fi
if [ `imtest ${outname}_merged` -eq 1 ]
then
  immv ${outname}_merged ${outname}_merged_old
fi

for mon in ${basedir}/monkeys/*
do
  echo $mon
  mean=`fslstats ${mon}/$inname -M`
  fslmaths ${mon}/$inname -mul 100 -div $mean $tmpname
  if [ `imtest ${outname}_merged` -eq 0 ]
  then
    echo making a new one
    imcp $tmpname ${outname}_merged
  else
    echo appending to old one
    fslmerge -t ${outname}_merged ${outname}_merged $tmpname
  fi
done

rm -f $tmpname
fslmaths ${outname}_merged -Tmean $outname