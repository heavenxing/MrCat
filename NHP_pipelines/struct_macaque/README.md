Preprocessing of macaque in-vivo structural images
--------------------------------------------------
A pipeline for structural preprocessing, with example data.


SCRIPTS
-------
wrapper_struct_macaque.sh   Wrapper and entry script
struct_macaque.sh      	    Core script, doing the grunt work
robustfov_macaque.sh        Crop large images to a robust field-of-view
bet_macaque.sh              Providing an initial brain extraction


HCPSCRIPTS
-------
HCP_scripts/RobustBiasCorr.sh		Taken from HCP Pipelines to correct spatial bias
HCP_scripts/FixNegVal.sh        Taken from HCP Pipelines to prevent negative values
HCP_scripts/fnirt_1mm.cnf      	Configuration file for accurate (and slow) fnirt


EXAMPLE DATA
------------
in_vivo/example_data/struct/struct.nii.gz   Example in-vivo macaque whole head T1w MRI


MACAQUE_REFERENCE
----------
ref_macaque/F99	F99 template in F99 space
ref_macaque/MNI	MNI mulatta template in MNI space
ref_macaque/SL	McLaren template in Saleem-Logothetis space


For more info please type:  sh struct_macaque.sh
