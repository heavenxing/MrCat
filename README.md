#### Introduction

The MR Comparative Anatomy Toolbox (Mr Cat) is a collection of Matlab scripts and functions developed by members and collaborators of the Cognitive Neuroecology Lab at the Radboud University Nijmegen and the University of Oxford. It contains code that we have used to analyze magnetic resonance imaging data obtained from different types of brains.

At the moment, only a very limited set of scripts and functions is available purely as a pilot project. This will hopefully develop as new code is created and the associated papers published. Note that the code here on GitHub might differ from the code used for the papers, as we aim to keep updating all scripts and functions.

Please note that all code are made available purely as a pilot project and you are using it completely at your own risk. See also LICENSE.md.

Below follows a short description of how we used the scripts and functions currently available.

#### K-means

K-means clustering is already well implemented in Matlab’s stats toolbox. However, we have implemented some separate versions and add-ons, partly to allow one to play with the algorithms. A fast k-means algorithm is implemented in `kmeans_fast.m`.

K-means can be sensitive to the initiation, multiple methods are implemented and handled by the wrapper `km_init.m` that can implement the kmeans++ initialization (Arthur and Vassilvitskii 2006, Stanford Infolab Technical Report), kd-tree (Redmond and Heneghan (2007, Patt Recog Lett) by calling `km_init_kdtree.m`), or the simple random seeding of the first centroid and spreading the rest out maximally (by calling `km_init_furthest.m`).

Visualizing the results can be done by showing the reordered connectivity matrix using `sort_CC_matrix.m`. The solutions can be evaluated using the hierarchy index described by Kahnt et al. (2012, J Neurosci) using `km_hierarchyindex.m`, the silhouette measure (Rousseeuw, 1987, J Computat Appl Math) as implemented in Matlab and called using  wrapper `km_silhouette.m`, and the variation of information (Meila, 2007, J Multivar Anal) using `km_vi.m` (which calls `columnentropy.m` and `mutualinformation.m`).

#### Visualization

Visualizing tractography results across a whole brain is difficult. We have found that using the SPM-like maximum intensity projection (‘glass brain’; `glass_projection.m`) is quite effective to quickly see where in the whole brain a tract goes.Publication quality figures of the course of tracts are produced using `tract3D.m`.Connectivity profiles can often be summarized as a connectivity fingerprint (cf. Passingham et al., 2002, Nat Rev Neurosci). In order to do to so effectively we use `spider_wedge.m`.To deal with the skewed distribution of the fdt_paths resulting from FSL probtrackx we often log transform and maximum normalize them using `log_threshold.m`.#### Connectivity fingerprint matching
Connectivity fingerpint matching, or ‘spider matching’, refers to the quantitative comparison of profiles, which is another way of saying that we are comparing vectors (‘spiders’) that represent meaningful things such as connectivity fingerprints.There are two measures of comparing the spiders currently implemented: the Manhattan distance measure (`manhattan.m`) and the cosine similarity measure (`cosine_similarity.m`).

These are called by the different `sm_*.m` functions that allow you to compare a group of subjects’ connectivity fingerprints to a template by permuting over arms of the spider (`sm_compare2template.m`) or compare two groups of subjects by permuting over group membership (`sm_comparegroups.m`). All these methods are described in more detail in Mars et al. (in revision).
