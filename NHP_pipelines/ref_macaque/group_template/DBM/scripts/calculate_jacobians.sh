#!/bin/sh
#
# Script to calculate Jacobian and log-jacobian maps
#

if [ "$#" -ne 3 ] && [ "$#" -ne 4 ]
then
  echo Usage: 
  echo $0 ref basedir warps
  echo or
  echo $0 ref basedir warps jid
  exit 1
fi

basedir=$2

ll=0.1
ul=10
txtname=`mktemp ${basedir}/log/calculate_jacobians.txt.XXXXXX`
txtname2=`mktemp ${basedir}/log/log_jacobians.txt.XXXXXX`
jacname=`echo $3 | sed 's;_warps;_jac;'`
logname=`echo $jacname | sed 's;_jac;_log_jac;'`
rlogname=`echo $jacname | sed 's;_jac;_restricted_log_jac;'`

for mon in ${basedir}/monkeys/*
do
  echo "fnirtfileutils --ref=$1 --in=${mon}/$3 --jac=${mon}/$jacname" >> $txtname
  echo "fslmaths ${mon}/$jacname -log ${mon}/$logname" >> $txtname2
  echo "fslmaths ${mon}/$jacname -max $ll -min $ul -log ${mon}/$rlogname" >> $txtname2
done

if [ "$#" -eq  4 ]
then
  jid=`fsl_sub -q veryshort.q -j $4 -t $txtname`
else
  jid=`fsl_sub -q veryshort.q -t $txtname`
fi
jid=`fsl_sub -q veryshort.q -j $jid -t $txtname2`

echo $jid