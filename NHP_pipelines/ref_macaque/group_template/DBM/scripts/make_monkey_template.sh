#!/bin/sh
#
# Script to create monkey template and to register
# all monkeys to it.
#

if [ "$#" -ne 1 ]
then
  echo Usage $0 dirname
  exit 1
fi

#
# Make sure basedir exists
#
basedir=$1
if [ ! -d $basedir ]
then
  echo $0: Directory $basedir does not exist
  exit 1
fi

#
# Make sure basedir contains everything we need
#
if [ ! -d "${basedir}/config" ] || [ ! -d "${basedir}/monkeys" ] || [ ! -d "${basedir}/MNITemplate" ]
then
  echo $0: The directory $basedir lacks neccessary subdirectories
  exit 1
fi
if [ ! -d "${basedir}/log" ]
then
  echo $0: Creating subdirectory ${basedir}/log
  mkdir ${basedir}/log
fi
if [ ! -d "${basedir}/Template" ]
then
  echo $0: Creating subdirectory ${basedir}/Template
  mkdir ${basedir}/Template
fi
if [ ! -d "${basedir}/Results" ]
then
  echo $0: Creating subdirectory ${basedir}/Results
  mkdir ${basedir}/Results
fi

#
# First flirt and fnirt all to MNI monkey template
#
jid=`./flirt_all.sh ${basedir}/MNITemplate/macaque_50_model-MNI_brain $basedir structural_brain struct2mni.mat`
jid=`echo $jid | awk '{ print $NF }'`
echo Job-id for flirting is $jid
jid=`./fnirt_all_first_level.sh ${basedir}/MNITemplate/macaque_50_model-MNI ${basedir}/MNITemplate/macaque_50_model-MNI_mask_dil $basedir structural struct2mni.mat ${basedir}/config/T1_2_monkey_mni.cnf struct2mni $jid`
jid=`echo $jid | awk '{ print $NF }'`
echo Job-id for initial fnirting to monkey-MNI template is $jid
 
#
# Resample registered images and make a template
#
jid=`./resample_all.sh ${basedir}/MNITemplate/macaque_50_model-MNI $basedir structural struct2mni_warps structural_warped_2_mni $jid`
jid=`echo $jid | awk '{ print $NF }'`
jid=`fsl_sub -q veryshort.q -j $jid ./make_average.sh structural_warped_2_mni ${basedir}/Template/mean_warped_2_mni $basedir`

#
# re-fnirt to the study template
#
jid=`./fnirt_all_first_level.sh ${basedir}/Template/mean_warped_2_mni ${basedir}/MNITemplate/macaque_50_model-MNI_mask_dil $basedir structural struct2mni.mat ${basedir}/config/T1_2_monkey_mni.cnf struct2template_level_1 $jid`
jid=`echo $jid | awk '{ print $NF }'`
echo Job-id for first level fnirting to study template is $jid

#
# Resample these new registered images and make a second template
#
jid=`./resample_all.sh ${basedir}/Template/mean_warped_2_mni $basedir structural struct2template_level_1_warps structural_warped_2_template_level_1 $jid`
jid=`echo $jid | awk '{ print $NF }'`
jid=`fsl_sub -q veryshort.q -j $jid ./make_average.sh structural_warped_2_template_level_1 ${basedir}/Template/mean_warped_2_template_level_1 $basedir`

#
# Perform a set of higher level (resolution)
# fnirts. Each time creating a new average to
# use as template for next level
#

for level in {1..5}
do
  jid=`./fnirt_all_higher_level.sh ${basedir}/Template/mean_warped_2_template_level_${level} ${basedir}/MNITemplate/macaque_50_model-MNI_mask_dil $basedir structural struct2template_level_${level}_warps struct2template_level_1_int ${basedir}/config/T1_2_template_level$((level+1)).cnf struct2template_level_$((level+1)) $jid`
  jid=`echo $jid | awk '{ print $NF }'`
  echo Job-id for level $((level+1)) fnirting to study template is $jid
  jid=`./resample_all.sh ${basedir}/Template/mean_warped_2_template_level_${level} $basedir structural struct2template_level_$((level+1))_warps structural_warped_2_template_level_$((level+1)) $jid`
  jid=`echo $jid | awk '{ print $NF }'`
  jid=`fsl_sub -q veryshort.q -j $jid ./make_average.sh structural_warped_2_template_level_$((level+1)) ${basedir}/Template/mean_warped_2_template_level_$((level+1)) $basedir`
done

#
# Calculate the jacobians and log-jacobians for this final level
#
jid=`./calculate_jacobians.sh ${basedir}/Template/mean_warped_2_template_level_$((level+1)) $basedir struct2template_level_$((level+1))_warps $jid`
jid=`echo $jid | awk '{ print $NF }'`

#
# Collect them to 4D file for randomise
#
fsl_sub -q veryshort.q -j $jid ./collect_to_4D.sh $basedir struct2template_level_$((level+1))_jac ${basedir}/Results/struct2template_level_$((level+1))_jac
fsl_sub -q veryshort.q -j $jid ./collect_to_4D.sh $basedir struct2template_level_$((level+1))_jac ${basedir}/Results/struct2template_level_$((level+1))_log_jac
fsl_sub -q veryshort.q -j $jid ./collect_to_4D.sh $basedir struct2template_level_$((level+1))_jac ${basedir}/Results/struct2template_level_$((level+1))_restricted_log_jac
