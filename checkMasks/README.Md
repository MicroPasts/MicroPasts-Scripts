#Notes and Usage

This is a script for manipulating the crowdsourced photo-mask data in cases where an application involves several different objects to be me modelled and where not all the task runs have not yet been completed in their entirety.

checkMasks.R -- A set of example R commands that are currently run locally on an example set of photomasking tasks, so paths need to be changed. The workflow extracts all unique object accession numbers based on the parent folder of the images with the same URL. These are then check for whether a minum number of tasks have been completed for ALL photos relatign to that object. If the object has sufficient masks to proceed with 3D modelling then it is returned in a final list of 'ready' objects (than could then, for example, be downloaded via downloadsS3.py)


