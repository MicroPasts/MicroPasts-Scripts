## Image mask from multiple polygonal areas described in a json file
## TODO: set up a loop through all completed tasks in a given application, not just one.
## Andy Bevan 15-Jun-2014

## Currently for Python 2.7.5 (tested on MacOSX 10.9.2) launched in a virtual environment:
## ~/Virtualenvs/immerges/bin/python
## Below is an example of installing libraries in such a virtual environment using pip:
## sudo ~/Virtualenvs/immerges/bin/pip install boto

# Libraries
from PIL import Image # Pillow/PIL needs libjpeg support
from PIL import ImageDraw
import urllib2
import json
import re
import numpy as np
from boto.s3.connection import S3Connection
import os

## Global settings ##
os.chdir('Documents/research/micropasts/pyscripts/photomasking/working')
maskthresh = 0.5 # masking threshold (e.g. half of contributors' polygons overlap)
app = 'photomasking'
pybinst = 'http://crowdsourced.micropasts.org'
objbucket = '1911 5-15 2'

###################################

# Get the raw jpg files from download directory
ext = ['.JPG', '.jpg', '.jpeg', '.JPEG']
files = [ f for f in os.listdir('.') if f.endswith(tuple(ext)) ]

# Open an example image
img = Image.open(files[0])
#img.show()

# # Get JSON data for tasks and find task ID for this file
lkup = objbucket + '/' + files[0]
url = str(pybinst) + '/app/' + str(app) + '/tasks/export?type=task&format=json'
jurl = urllib2.urlopen(url)
jtasks = json.loads(jurl.read())

for elm in range(0, len(jtasks)):
    onetask = jtasks[elm]
    onetaskurl = onetask['info']['url_b'].encode('utf-8')
    if re.search(lkup, onetaskurl): taskID = onetask['id']

# Get JSON data for task runs
url = str(pybinst) + '/app/' + str(app) + '/' + str(taskID) + '/results.json'
jurl = urllib2.urlopen(url)
jtaskruns = json.loads(jurl.read())

# Loop through and extract outlines
polys = [] # Empty list for polygons
contribs = len(jtaskruns)  # number of contributors to this task
for a in range(0, contribs):
    jtaskrun = jtaskruns[a]  #one contributor
    # Extract the outline and convert to tuples
    o0 = jtaskrun['info']['outline'][0][0]
    p = [] # Empty list for outline vertices
    h = img.size[1] # Get image height
    for x in range(0, len(o0)):
        xy = o0[x]
        xy[1] = h - xy[1] # reverse y-coordinates
        p.append(tuple(xy))
    polys.append(p)

# Add these polygons incrementally to a mask
mask = Image.new("L", img.size, color=0)
mask = np.asarray(mask)
for x in polys:
    imtmp=Image.new("L", img.size, color=0)
    draw=ImageDraw.Draw(imtmp)
    draw.polygon(x, fill=255/float(len(polys)))
    imtmp = np.asarray(imtmp)
    mask = mask+imtmp

# Look for holes and convert to polygons if present
hpolys = [] # Empty list for hole polygons
for a in range(0, contribs):
    jtaskrun = jtaskruns[a]  #one contributor
    hls = jtaskrun['info']['holes'] # check for presence of holes data
    if hls:
        # Extract the outline and convert to tuples
        h0 = jtaskrun['info']['holes'][0][0]
        ph = [] # Empty list for outline vertices
        h = img.size[1] # Get image height
        for x in range(0, len(h0)):
            xy = h0[x]
            xy[1] = h - xy[1] # reverse y-coordinates
            ph.append(tuple(xy))
        hpolys.append(ph)

# Create a reverse mask for these polygon holes if necessary and subtract
if hpolys:
    hmask=Image.new("L", img.size, color=0)
    hmask = np.asarray(hmask)
    for y in hpolys:
        imtmp=Image.new("L", img.size, color=0)
        draw=ImageDraw.Draw(imtmp)
        draw.polygon(y, fill=255/float(len(polys)))
        imtmp = np.asarray(imtmp)
        hmask = hmask+imtmp

# Combine if necessary
if hpolys:
    hmask = hmask * -1
    mask = mask + hmask
    mask[mask < 0] = 0
    mask = Image.fromarray(mask)
    mask = mask.convert(mode="L")
else:
    mask = Image.fromarray(mask)

# Convert to binary mask based on threshold (see global settings)
maskbin = Image.eval(mask, lambda px: 0 if px <= 255*maskthresh else 255)

# # Compare
# img.show()
# mask.show()
# maskbin.show()

# Save image mask (no EXIF but does not matter for mask)
fn = imnameonly + '_mask.JPG'
maskbin.save(fn)

# So these three files (the raw jpg, the mask jpg and the json data) should be archived together on MicroPasts AWS. This could simply involve pusing the mask file and json data to the bucket where the raw image already resides.




