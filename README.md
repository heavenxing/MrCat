#### Introduction

The MR Comparative Anatomy Toolbox (Mr Cat) is a collection of Matlab scripts and functions developed by members and collaborators of the Cognitive Neuroecology Lab at the Radboud University Nijmegen and the University of Oxford. It contains code that we have used to analyze magnetic resonance imaging data obtained from different types of brains.

At the moment, only a very limited set of scripts and functions is available purely as a pilot project. This will hopefully develop as new code is created and the associated papers published.

Below follows a short description of how we used the scripts and functions currently available.

#### Visualization

Visualizing tractography results across a whole brain is difficult. We have found that using the SPM-like maximum intensity projection (‘glass brain’; `glass_projection.m`) is quite effective to quickly see where in the whole brain a tract goes.Publication quality figures of the course of tracts are produced using `tract3D.m`.Connectivity profiles can often be summarized as a connectivity fingerprint (cf. Passingham et al., 2002, Nat Rev Neurosci). In order to do to so effectively we use `spider_wedge.m`.To deal with the skewed distribution of the fdt_paths resulting from FSL probtrackx we often log transform and maximum normalize them using `log_threshold.m`.#### Connectivity fingerprint matching
Connectivity fingerpint matching, or ‘spider matching’, refers to the quantitative comparison of profiles, which is another way of saying that we are comparing vectors (‘spiders’) that represent meaningful things such as connectivity fingerprints.There are two measures of comparing the spiders currently implemented: the Manhattan distance measure (`manhattan.m`) and the cosine similarity measure (`cosine_similarity.m`).

These are called by the different `sm_*.m` functions that allow you to compare a group of subjects’ connectivity fingerprints to a template by permuting over arms of the spider (`sm_compare2template.m`) or compare two groups of subjects by permuting over group membership (`sm_comparegroups.m`). All these methods are described in more detail in Mars et al. (in revision).
