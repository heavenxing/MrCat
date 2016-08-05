#!/bin/sh
#
# Simple script to make a new average
#

if [ "$#" -ne 3 ]
then
  echo Usage: 
  echo $0 basedir inname outname
  exit 1
fi
basedir=$1
inname=$2
outname=$3

if [ `imtest $outname` -eq 1 ]
then
  immv $outname ${outname}_old
fi

for mon in ${basedir}/monkeys/*
do
  if [ `imtest $outname` -eq 0 ]
  then
    imcp ${mon}/$inname ${outname}
  else
    fslmerge -t ${outname} ${outname} ${mon}/$inname
  fi
done

fslmaths ${outname} -Tmean ${outname}_mean