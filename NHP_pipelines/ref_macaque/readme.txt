----------
# Macaca #
----------
This document describes the folder structure and pipeline to process standard
macaque templates and atlas spaces. So far, no atlases are included although
the atlases originally included with the templates can be found in the
respective "orig" folder.


"orig"
------
holds the original data

  F99 template (F99 space)
    http://brainvis.wustl.edu/wiki/index.php/Caret:Atlases
    http://sumsdb.wustl.edu/sums/directory.do?dir_id=6585200

    The dataset is created for the Caret software package from the van Essen
    lab. Caret has been largely replaced by the Workbench package as part of
    the Human Connectome Project. The workbench 0.83 tutorial
    (./proc/Connectome_WB_Tutorial_UserGuide_beta_v0.83.pdf) describes how to
    use wb_import to convert caret files to more general formats. Please note
    that you can only import one hemisphere at a time, so please also download
    the data for each hemisphere separately, instead of already merged.

    When using, cite:
    Van Essen DC (2002) Windows on the brain: The emerging role of atlases and
    databases in neuroscience. Curr Opin Neurobiol 12:574-579

  McLaren template (Saleem space)
    http://brainmap.wisc.edu/pages/2-Rhesus-Macaque-Atlases-for-functional-and

    Data is in nifti format, in good shape, and the brain is already extracted.
    To get a brain mask one could simply binarise the image, but it is more
    sensible to use a relative threshold to exclude the 25% darkest voxels.

    When using, cite:
    McLaren DG, Kostmatka KJ, Oakes TR, Kroenke CD, Kohama SG, Matochik JA,
    Ingram DK, Johnson SC (2009) A Population-Average MRI-Based Atlas Collection
    of the Rhesus Macaque. Neuroimage 45:52-9.
    McLaren DG, Kosmatka KJ, Kastman EK, Bendlin BB, Johnson SC (2010) Rhesus
    Macaque Brain Morphometry: A Methodological Comparison of Voxel-Wise
    Approaches. Methods 50:157-65. 

  MNI template (MNI space)
    http://www.bic.mni.mcgill.ca/ServicesAtlases/Macaque
    http://www.bic.mni.mcgill.ca/ServicesAtlases/RhesusDownload

    Data is in nifti format, but contains artefacts where bright spots
    (especially from the eyes) leak into CSF and grey matter. The "proc" folder
    contains some scripts to correct for these artefacts and to extract a brain
    mask from the template. The data comes in three groups of averages, of 7
    macaca mulatta, 18 macaca fascularis, and both together labelled "mix".

    When using, cite:
    Chakravarty MM, Frey S, Collins DL (2008) Digital atlas of the monkey brain
    in stereotactic co-ordinates. In: Paxinos G, Huang XF, Petrides M, Toga AW.
    The Rhesus Monkey Brain In Stereotactic Coordinates. Elsevier.
    Frey S, Pandya DN, Chakravarty MM, Petrides M, Collins DL (2009) MNI monkey
    space. Neuroscience Research 65:S130
    Frey S, Pandya DN, Chakravarty MM, Bailey L, Petrides m, Collins DL (2011)
    An MRI based average macaque monkey stereotaxic atlas and space (MNI monkey
    space). NeuroImage 55:1435-1442

"proc"
------
Processing of the original template data to good quality nifti format. This
folder has a "scripts" subfolder that contains all code to do the processing.
Please note that this code depends on FSL and Workbench being installed.

  F99 template
    script: proc_F99.sh, bet_F99.sh, RobustBiasCorr.sh, fnirt_1mm.cnf
    Uses wb_import and wb_command to convert the Caret files to gii and nii.
    Then through bet_F99.sh creates a brain mask through non-linear registration
    to the McLaren template. This can take a couple of hours. Please note that
    this script does not (yet) process the F6 space. Mostly because van Essen
    advised to simply register to the F99 template instead. Theoretically,
    registration to the F6 (which is an average of 6 samples) should be more
    robust but the surface of the F6 template is less well defined. So the
    registration to the F99 template (single sample) is often good enough, and
    especially well suited if you want to project your data to the surface.

  McLaren template
    script: proc_McLaren.sh
    The McLaren template images come with a ridiculously large field of view.
    This script takes a sensible region of interest (just slightly larger than
    the F99 template). This script creates two brain masks by thresholding the
    template, once approximating a standard size, and once quite strict.
    Two things to note: First, the template is an average of extracted brains,
    so the brains are very gradually becoming darker from the edges. This
    necessitates the use of masks during registration. For flirt you can use the
    same file as input and to weight the input. For fnirt you best use the
    strict brain mask. With the default mask the brain would be be estimated to
    be smaller than it is. With a strict brian mask the result is better.
    Second, the McLaren template comes with SPM normalise parameters to and from
    F99 space. I included some SPM jobs to convert these parameters to
    deformation fields. It turns out they aren't good enough.

  MNI
    script: proc_MNI.sh, corr_MNI.sh, RobustBiasCorr.sh, [fnirt_1mm.cnf]
    The proc_MNI.sh script is mostly a wrapper around corr_MNI.sh. That script
    does the magic to correct the MNI. See over there for more info. There are
    two things two note: first, the script processes the mulatta and mix
    datasets, but only passes the mulatta onwards to the space directory. The
    final data comes in two resolutions, the original 0.25mm and resampled to
    more conventional 0.5mm.

  transformations
    script: register_templates.sh
    This script uses linear and then non-linear registration to create
    transformations from F99 to SL (and back), from MNI to SL (and back), and
    then the combination of these to get from F99 to MNI (and back). I have
    chosen to use the direct estimation from F99 to MNI by default, so that all
    transformation are independently and directly estimated. If you prefer that
    all warps are perfectly interchangeable and then I have provided the files
    with names post-padded with "_viaSL".


"F99"
-----
F99 space, based on a single macaca mulatta dataset used by the van Essen lab.
It is part of the Caret software package and includes surface files. For this
space also an F6 template exists that consists of the average of 6 animals
registered to F99 space.


"SL"
--------
D99-SL space, based on the histological atlas of Saleem & Logothetis (2006) but
defined in the volume by the average of 112 macaca mulatta (80 m, 32 f) as
described by McLaren et al (2008).


"MNI"
-----
MNI space, defined for both macaca fascularis (based on an average of 18 animals)
and for macaca mulatta (based on an average of 7 animals), or both together.
