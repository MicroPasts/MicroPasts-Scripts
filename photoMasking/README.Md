#Notes and Usage

This script assumes you have run downloadsS3.py to get a local set of photos for photomaksing from a MicroPasts Amazon S3 bucket.
It is meant to loop through the downloaded images and correpsonding json files of task runs for that image on the MicroPasts site
and create binary jpg mask files in the same local folder as the downloaded images. 

To use this script, first download a set of images for 3d modelling using the downloadsS3.py script.

The run the photoMasking script pointing to the directory in which these downloads are stored (and where the masks will be created). An example command line call (in a virtual environment) is:
`~/Virtualenvs/immerges/bin/python Documents/research/micropasts/pyscripts/photomasking/photoMasking/photoMasking.py -a 'photomasking' -t 0.5 -o '1911 5-15 2' -w 'Documents/research/micropasts/pyscripts/photomasking/working'`

