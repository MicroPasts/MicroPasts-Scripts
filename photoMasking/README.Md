#Notes and Usage

This script assumes you have run downloadsS3.py to get a local set of photos for photomaksing from a MicroPasts Amazon S3 bucket.
It is meant to loop through the downloaded images and corresponding json files of task runs for that image on the MicroPasts site
and create binary jpg mask files in the same local folder as the downloaded images. 

To use this script, first download a set of images for 3d modelling using the downloadsS3.py script.

The run the photoMasking script pointing to the directory in which these downloads are stored (and where the masks will be created). An example command line call (NB in this example python is working in a virtual environment on my computer called immerges) is:

~/Virtualenvs/immerges/bin/python Documents/research/micropasts/scripts/photomasking/photoMasking/photoMasking.py -a 'photomasking' -w 'Documents/research/micropasts/scripts/photomasking/working'

