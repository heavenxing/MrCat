#! /bin/sh

cd /vols/Data/daa/jsallet/learning_expt/monkeys/

#for s in oliver orson orvil peewee pleco pugsly puck pringle puzzle orca ranger scottie seb stevie jock jumanji saffron sea; do
for s in seb; do
 #   for session in 1 2 3; do
for session in 1; do
    mkdir ${s}_avg_${session}

     for file in structural_brain structural; do

	fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} -add ${s}_${session}3/${file} -add ${s}_${session}4/${file} -add ${s}_${session}5/${file} ${s}_avg_${session}/${s}_avg_${file}
 
#	#fslmerge -a ${s}_avg_${session}/${s}_avg_${file} ${s}_${session}1/${file} ${s}_${session}2/${file} ${s}_${session}3/${file} ${s}_${session}4/${file} ${s}_${session}5/${file}    
 
	done 

   done 

done 


#for s in jock jumanji; do

 #   for session in 3; do

  #mkdir ${s}_avg_${session}

#	for file in structural_brain structural; do

#fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} -add ${s}_${session}3/${file} -add ${s}_${session}4/${file} ${s}_avg_${session}/${s}_avg_${file}	

##fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file} ${s}_${session}3/${file} ${s}_${session}4/${file} 
 
#	done 

 #   done 

#done 


#for s in jumanji; do

#    for session in 2; do

 # mkdir ${s}_avg_${session}

  #      for file in structural_brain structural; do

#fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} -add ${s}_${session}3/${file} -add\ ${s}_${session}4/${file} ${s}_avg_${session}/${s}_avg_${file}

##fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file} ${s}_${session}3/${file} ${s}_${session}4/${file}                            

    #    done

    #done

#done





#for s in selena; do

  #  for session in 1 2; do

 # mkdir ${s}_avg_${session} 

#	for file in structural_brain structural; do

#fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} -add ${s}_${session}3/${file} -add ${s}_${session}4/${file} ${s}_avg_${session}/${s}_avg_${file}

	#fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file} ${s}_${session}3/${file} ${s}_${session}4/${file}   
 
#	done 

 #   done 

#done 



#for s in pilau; do

 #   for session in 2; do

  #mkdir ${s}_avg_${session}

#	for file in structural_brain structural; do

#	fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} -add ${s}_${session}3/${file} ${s}_avg_${session}/${s}_avg_${file}

	#fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file} ${s}_${session}3/${file}    
 
#	done 

 #   done 

#done 

#for s in orca; do

 #   for session in 1; do

 # mkdir ${s}_avg_${session}

#	for file in structural_brain structural; do

#	fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} ${s}_avg_${session}/${s}_avg_${file}

	#fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file}
#	done 

 #   done 

#done 

#for s in jumanji; do

 #   for session in 3; do

  #  mkdir  ${s}_${session}1/${file} 

#	for file in structural_brain structural; do

#	fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} ${s}_avg_${session}/${s}_avg_${file}

	#fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file}
#	done 

 #   done 

#done 

#for s in saffron sea sweet; do

 #   for session in 2 3 4; do

  # mkdir ${s}_avg_${session}

#	for file in structural_brain structural; do

#	fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} ${s}_avg_${session}/${s}_avg_${file}

	#fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file}  
 
#	done 

 #   done 

#done 


#for s in selena; do

 #   for session in 3; do

  #mkdir ${s}_avg_${session}

   #     for file in structural_brain structural; do
#
#fslmaths ${s}_${session}1/${file} -add ${s}_${session}2/${file} ${s}_avg_${session}/${s}_avg_${file}

#fslmerge -a ${s}_avg_${session}/${s}_avg_structural_brain_${session} ${s}_${session}1/${file} ${s}_${session}2/${file} ${s}_${session}3/${file} ${s}_${session}4/${file}                            

 #       done

  #  done
#
#done


