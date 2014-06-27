#!/usr/bin/python
## Convert MicroPasts photo-mask polygons to binary image masks (for 3D models)
## Andy Bevan 15-Jun-2014
__author__ = 'ahb108'
## Currently for Python 2.7.5 (tested on MacOSX 10.9.2) launched in a virtual environment:

# Libraries
from PIL import Image  # Pillow/PIL needs libjpeg support
from PIL import ImageDraw
import urllib2
import json
import re
import numpy as np
import argparse
import os

# Argument parser
parser = argparse.ArgumentParser(description='This is a script to combine vector polygon masks into a binary raster mask for 3d modelling.')
parser.add_argument('-a','--app',help='MicroPasts application', required=True)
parser.add_argument('-t','--thr',help='Masking threshold', required=True)
parser.add_argument('-o','--obj',help='Object to be masked', required=True)
parser.add_argument('-w','--wd', help='Working directory',required=True)
args = parser.parse_args()

# # Global settings ##
os.chdir(args.wd)
maskthresh = float(args.thr)
app = args.app
objbucket = args.obj
pybinst = 'http://crowdsourced.micropasts.org'

###################################

# Get the raw jpg files from download directory
ext = ['.JPG', '.jpg', '.jpeg', '.JPEG']
files = [ f for f in os.listdir('.') if f.endswith(tuple(ext)) ]

print("Masking each individual photograph...")
for q in range(0, len(files)):
# Open an example image
    img = Image.open(files[q])
    imnameonly = os.path.splitext(files[q])[0]
# Get JSON data for tasks and find task ID for this file
    lkup = objbucket + '/' + files[q]
    url = str(pybinst) + '/app/' + str(app) + '/tasks/export?type=task&format=json'
    jurl = urllib2.urlopen(url)
    jtasks = json.loads(jurl.read())

# Loop through looking for those tasks with the necessary
# look-up image (almost always one unless tasks have been duplicated,
# but allowing more than one just in case)
    imtasks = []
    for elm in range(0, len(jtasks)):
        onetask = jtasks[elm]
        onetaskurl = onetask['info']['url_b'].encode('utf-8')
        if re.search(lkup, onetaskurl): imtasks.extend([onetask['id']])
        
# Get JSON data for task runs (even if they are duplicated)
    jtaskruns = []
    for a in range(0, len(imtasks)):
        url = str(pybinst) + '/app/' + str(app) + '/' + str(imtasks[a]) + '/results.json'
        jurl = urllib2.urlopen(url)
        jtaskruns.extend(json.loads(jurl.read()))

# Loop through and extract outlines
    polys = []
    for a in range(0, len(jtaskruns)):
        jtaskrun = jtaskruns[a]  # one contributor
# Extract the outline and convert to tuples
        o0 = jtaskrun['info']['outline'][0][0]
        p = []  # Empty list for outline vertices
        h = img.size[1]  # Get image height
        for x in range(0, len(o0)):
            xy = o0[x]
            xy[1] = h - xy[1]  # reverse y-coordinates
            p.append(tuple(xy))
        polys.append(p)

# Add these polygons incrementally to a mask
    mask = Image.new("L", img.size, color=0)
    mask = np.asarray(mask)
    for x in polys:
        imtmp = Image.new("L", img.size, color=0)
        draw = ImageDraw.Draw(imtmp)
        draw.polygon(x, fill=255 / float(len(polys)))
        imtmp = np.asarray(imtmp)
        mask = mask + imtmp

# Look for holes and convert to polygons if present
    hpolys = []  # Empty list for hole polygons
    for a in range(0, len(jtaskruns)):
        jtaskrun = jtaskruns[a]  # one contributor
        hls = jtaskrun['info']['holes']  # check for presence of holes data
        if hls:
# Extract the outline and convert to tuples
            h0 = jtaskrun['info']['holes'][0][0]
            ph = []  # Empty list for outline vertices
            h = img.size[1]  # Get image height
            for x in range(0, len(h0)):
                xy = h0[x]
                xy[1] = h - xy[1]  # reverse y-coordinates
                ph.append(tuple(xy))
            hpolys.append(ph)

# Create a reverse mask for these polygon holes if necessary and subtract
    if hpolys:
        hmask = Image.new("L", img.size, color=0)
        hmask = np.asarray(hmask)
        for y in hpolys:
            imtmp = Image.new("L", img.size, color=0)
            draw = ImageDraw.Draw(imtmp)
            draw.polygon(y, fill=255 / float(len(polys)))
            imtmp = np.asarray(imtmp)
            hmask = hmask + imtmp

# Combine if necessary
    if len(hpolys) > 1:
        hmask = hmask * -1
        mask = mask + hmask
        mask[mask < 0] = 0
        mask = Image.fromarray(mask)
        mask = mask.convert(mode="L")
    else:
        mask = Image.fromarray(mask)
    
# Convert to binary mask based on threshold (see global settings)
    maskbin = Image.eval(mask, lambda px: 0 if px <= 255 * maskthresh else 255)
    
# Save image mask (no EXIF but does not matter for mask)
    fn = imnameonly + '_mask.JPG'
    maskbin.save(fn)

print("Done.")
