## Image mask from multiple polygonal areas described in a json file
## TODO: set up a loop through all completed tasks in a given application, not just one.
## Currently for Python 2.7.5 (tested on MacOSX 10.9.2)
## Andy Bevan 12-Apr-2014

# Libraries
from PIL import Image # Pillow/PIL needs libjpeg support
from PIL import ImageDraw
from urllib import urlretrieve
import urllib2
import json
import numpy as np
import os

## Global settings ##
os.chdir('Documents/research/micropasts/metalfinds/palstaves/models/masktest/json/working')
maskthresh = 0.5 # masking threshold (e.g. half of contributors' polygons overlap)
url = 'http://crowdsourced.micropasts.org/app/photomasking/6239/results.json'
# Alternatively, if that link's dead, the same example should be here.
#url = 'https://github.com/findsorguk/MicroPasts-Scripts/blob/master/examples/results.json'

###################################

# Get and save JSON file
jurl = urllib2.urlopen(url)
jtasks = json.loads(jurl.read())

# Get the image URL for this task
jtask = jtasks[0]  #example contributor
imurl = jtask['info']['img'] # Amazon AWS URL of image
imurl = imurl.encode('ascii','ignore')  # convert to ascii
imurl = urllib2.quote(imurl, safe="%/:=&?~#+!$,;'@()*[]")  # sort out dodgy characters
imname = imurl.rsplit('/',1)[1] # Image filename
imnameonly = os.path.splitext(imname)[0]

# Download raw image (keeps EXIF metadata better) and json file
fni = os.path.join(os.getcwd(),imname)
urlretrieve(imurl, fni)
fnj = os.path.join(os.getcwd(),imnameonly + ".json")
urlretrieve(url, fnj)

# Open image
img = Image.open(fni)
#img.show()

# Loop through and extract outlines
polys = [] # Empty list for polygons
contribs = len(jtasks)  # number of contributors to this task
for a in range(0, contribs):
    jtask = jtasks[a]  #one contributor
    # Extract the outline and convert to tuples
    o0 = jtask['info']['outline'][0][0]
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

# # Drawing image and an example outline.
# draw = ImageDraw.Draw(img) 
# draw.polygon(polys[1])
# img.show()

# Look for holes and convert to polygons if present
hpolys = [] # Empty list for hole polygons
for a in range(0, contribs):
    jtask = jtasks[a]  #one contributor
    hls = jtask['info']['holes'] # check for presence of holes data
    if hls:
        # Extract the outline and convert to tuples
        h0 = jtask['info']['holes'][0][0]
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




