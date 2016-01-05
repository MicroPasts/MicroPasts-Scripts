#!/usr/bin/python
## Download files from Amazon S3 (e.g. raw photos for 3D models)
## Andy Bevan 15-Jun-2014, updated 21-Nov-2014
## Daniel Pett updated 05-Jan-2016
__author__ = 'ahb108'
## Currently for Python 2.7.5 (tested on MacOSX 10.9.2) launched in a virtual environment:

from PIL import Image  # Pillow with libjpeg support
from PIL import ImageDraw
import urllib3
import json
import re
import numpy as np
import argparse
import os 
import urllib2
import zipfile

# Argument parser
parser = argparse.ArgumentParser(description='This is a script to combine vector polygon masks into a binary raster mask for 3d modelling.')
parser.add_argument('-a','--app',help='MicroPasts application', required=True)
parser.add_argument('-w','--wd', help='Working directory',required=True)
args = parser.parse_args()

## Global settings ##
os.chdir(args.wd)
app = args.app
pybinst = 'http://crowdsourced.micropasts.org'

###################################

# Get the raw jpg files from working directory
ext = ['.JPG', '.jpg', '.jpeg', '.JPEG']
files = [ f for f in os.listdir('.') if f.endswith(tuple(ext)) ]

print("Masking each individual photograph...")
for q in range(0, len(files)):
    # Open an example image
    img = Image.open(files[q])
    imnameonly = os.path.splitext(files[q])[0]

    # Get JSON data for tasks and find task ID for this file
    downloadURL = str(pybinst) + '/project/' + str(app) + '/tasks/export?type=task&format=json'   
    outputFilename = str(app) + '_task.json'

    # Download JSON file to working direcory
    response = urllib2.urlopen(downloadURL)
    zippedData = response.read()

    # Save data to disk
    output = open(outputFilename,'wb')
    output.write(zippedData)
    output.close()

    # Extract the data
    zfobj = zipfile.ZipFile(outputFilename)
    for name in zfobj.namelist():
        uncompressed = zfobj.read(name)

    # Save uncompressed data to disk
    outputFilename = name
    output = open(outputFilename,'wb')
    output.write(uncompressed)
    output.close()

    with open(outputFilename) as data_file:    
        jtasks = json.load(data_file)

    # Loop through looking for those tasks with the necessary look-up image (almost always one 
    # unless tasks have been duplicated, but allowing more than one just in case)
    imtasks = []
    for elm in range(0, len(jtasks)):
        onetask = jtasks[elm]
        onetaskurl = onetask['info']['url_b'].encode('utf-8')
        if re.search(files[q], onetaskurl): imtasks.extend([onetask['id']])

    # Get JSON data for task runs (even if they are duplicated)
    jtaskruns = []
    for a in range(0, len(imtasks)):
        downloadURL = str(pybinst) + '/project/' + str(app) + '/' + str(imtasks[a]) + '/results.json'     
        outputFilename = str(app) + str(imtasks[a]) + '_task_run.json'

        # Download JSON files to working direcory
        response = urllib2.urlopen(downloadURL)
        fileData = response.read()

        # Save data to disk
        output = open(outputFilename,'wb')
        output.write(fileData)
        output.close()

        with open(outputFilename) as data_file:    
            jtaskruns.extend(json.load(data_file))
            
    # Loop through and extract outlines 
    for a in range(0, len(jtaskruns)):
        jtaskrun = jtaskruns[a]  # one contributor
        imtmp = Image.new("L", img.size, color=0)
        draw = ImageDraw.Draw(imtmp)
        # Loop through outline (or possible multiple outline polygons)
        for outs in range(0, len(jtaskrun['info']['outline'])):
            # Extract the outline and convert to tuples
            o0 = jtaskrun['info']['outline'][outs][0]
            p = []  # Empty list for outline vertices
            h = img.size[1]  # Get image height
            for x in range(0, len(o0)):
                xy = o0[x]
                xy[1] = h - xy[1]  # reverse y-coordinates
                p.append(tuple(xy))
            draw.polygon(tuple(p), fill=255)
        # Loop through holes in same way
        for hls in range(0, len(jtaskrun['info']['holes'])):
            h0 = jtaskrun['info']['holes'][hls][0]
            ph = []
            for x in range(0, len(h0)):
                xy = h0[x]
                xy[1] = h - xy[1]
                ph.append(tuple(xy))
            draw.polygon(tuple(ph), fill=0)
        # imtmp.show()
        if jtaskrun['user_id'] is None:
            fn = imnameonly + '_mask_' + str(a) + '_anon.JPG'
        else:
            fn = imnameonly + '_mask_' + str(a) + '_user' + str(jtaskrun['user_id']) + '.JPG'
        imtmp.save(fn)
        if a is 1:
            fn1 = imnameonly + '_mask.JPG'
            imtmp.save(fn1)

print("Done.")
