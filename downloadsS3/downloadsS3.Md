#Notes and Usage

This script downloads all files from a specific Amazon S3 bucket that has been granted public access.

It has currently been tested for Python 2.7.5 (on MacOSX 10.9.2) launched in a virtual environment. For example:
`~/Virtualenvs/immerges/bin/python`
Below is an example of installing libraries in such a virtual environment using pip:
`sudo ~/Virtualenvs/immerges/bin/pip install boto`

To use this script, first identify an object on MicroPasts, for instance, by looking at:
[http://crowdsourced.micropasts.org/app/photomasking/tasks/export?type=task&format=json]
Looking at the above example, you will see that task 6421 is listed first and refers to the following S3 bucket:
[http://micropasts-palstaves.s3.amazonaws.com/Palstaves-photos-3D_13Feb14/Palstaves_Burnham-on-Crouch-Essex/1911 5-15 2/IMG_1668.JPG]

So initially we simply want to download all photos associated with this bucket, for which an example command line call (in a virtual environment) is:
`~/Virtualenvs/immerges/bin/python Documents/research/micropasts/pyscripts/photomasking/downloadsS3.py -b 'http://micropasts-palstaves.s3.amazonaws.com/Palstaves-photos-3D_13Feb14/Palstaves_Burnham-on-Crouch-Essex/1911 5-15 2' -w 'Documents/research/micropasts/pyscripts/photomasking/working'`