#! /usr/bin/env python

# Copyright 2015 Tom SF Haines

# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

import os.path
import argparse
import subprocess

import json
from collections import defaultdict



# Handle command line arguments...
parser = argparse.ArgumentParser(description='Parses an entire directory of amphora profile source images, running the conversion script and generating the outputs for all of them. Has makefile behaviour, so it only processes a file if it has not already been processed (output does not exist or has a modification date earlier than the source file).')

parser.add_argument('-f', '--force', help='Forces it to process all files, even if they have already been processed. Should only be necesary when making modifications to the scripts.',  default=False, action='store_true')
parser.add_argument('-r', '--render', help='Makes it render an image with each file - this can take a while!',  default=False, action='store_true')

parser.add_argument('-l', '--left', help='Makes it use the left handle only, mirroring it to get the right handle. helps for some dodgy users.',  default=False, action='store_true')


parser.add_argument('-t', '--tail', help="Will only process shapefiles if they end with the provided string, before the file extension. It defaults to 'forBlender'.", type=str, default='forBlender')
parser.add_argument('-b', '--blender', help="Where to find Blender on the operating system; default to '~blender/blender', the assumption on Mac/Linux that it is in the folder 'blender' under your home directory.", type=str, default='~/blender/blender')

parser.add_argument('dir', help='Directory it searches for shape files.')


args = parser.parse_args()


## For conveniance - assume the Blender script is in the same directory as this one, and pretend its an argument...
args.script = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'vesselprofiling_3Dblend.py')

## Convert the directory to a full path...
args.dir = os.path.realpath(os.path.expanduser(args.dir))

## Ditto for blender location...
args.blender = os.path.realpath(os.path.expanduser(args.blender))



# Search entire directory structure, find all files that we may need to process...
shape_files = []

def search(path):
  for child in os.listdir(path):
    full = os.path.join(path, child)
    
    if os.path.isdir(full): # Recurse into directories
      search(full)
    
    elif os.path.isfile(full) and full.endswith(args.tail + '.shp'):
      shape_files.append(full[:-4]) # [:-4] to remove the extension.


search(args.dir)

print('Found %i shape files' % len(shape_files))



# Second pass - cull down to those that have not already been processed...
if args.force:
  jobs = shape_files[:] # Do them all if force is True.

else:
  jobs = []
  
  for path in shape_files:
    test = (path + '.png') if args.render else (path + '_manifold.obj')
    
    if (not os.path.exists(test)) or (os.path.getmtime(test) < os.path.getmtime(path + '.shp')):
      jobs.append(path)


already_done = len(shape_files) - len(jobs)

if already_done>0:
  print('%i have already been processed - skipping them.' % already_done)



# Do the work - loop the files and run the script on each in turn...
for i, job in enumerate(jobs):
  print('Processing %i of %i' % (i+1, len(jobs)))
  print('    ' + job)
  
  cmd = [args.blender, '-b', '--python', args.script, '--', job]
  if args.render:
    cmd.append('render')
  if args.left:
    cmd.append('left')
  
  print cmd
  subprocess.call(cmd)



# Collate all the generated statistics into a spreadsheet...
stats = defaultdict(dict) # Indexed [key][amphora]

for base in shape_files:
  # Open the json file...
  fn = base + '_stats.json'
  if not os.path.exists(fn):
    print('Warning: Stats file for %s not found' % base)
    continue
  
  amphora = os.path.split(os.path.split(base)[0])[1] # Parent directory
  
  f = open(fn, 'r')
  data = json.load(f)
  f.close()
  
  for key, value in data.items():
    stats[key][amphora] = value


columns = stats.keys()
columns.sort()

rows = stats['height'].keys()
rows.sort()

f = open('stats.csv', 'w')
f.write('id,' + ','.join(columns) + '\n')

for row in rows:
  values = [str(stats[column][row]) for column in columns]
  f.write(row+','+','.join(values) + '\n')

f.close()
