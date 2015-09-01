#### Introduction

The MR Comparative Anatomy Toolbox (Mr Cat) is a collection of Matlab scripts and functions developed by members and collaborators of the [Cognitive Neuroecology Lab](www.neuroecologylab.org) at the Radboud University Nijmegen and the University of Oxford. It contains code that we have used to analyze magnetic resonance imaging data obtained from different types of brains.

At the moment, only a very limited set of scripts and functions is available purely as a pilot project. This will hopefully develop as new code is created and the associated papers published.

Below follows a short description of how we used the scripts and functions currently available.

#### Visualization

Visualizing tractography results across a whole brain is difficult. We have found that using the SPM-like maximum intensity projection (‘glass brain’; `glass_projection.m`) is quite effective to quickly see where in the whole brain a tract goes.Publication quality figures of the course of tracts are produced using `tract3D.m`.Connectivity profiles can often be summarized as a connectivity fingerprint (cf. Passingham et al., 2002, Nat Rev Neurosci). In order to do to so effectively we use `spiderwedge.m`.To deal with the skewed distribution of the fdt_paths resulting from FSL probtrackx we often log transform and maximum normalize them using `log_threshold.m`.