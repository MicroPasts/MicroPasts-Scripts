#!/usr/bin/python
## Download files from Amazon S3 (e.g. raw photos for 3D models)
## Andy Bevan 15-Jun-2014
__author__ = 'ahb108'
## Currently for Python 2.7.5 (tested on MacOSX 10.9.2) launched in a virtual environment:

from boto.s3.connection import S3Connection
import argparse
import os

# Argument parser
parser = argparse.ArgumentParser(description='This is a script to download batches of files from a specified Amazon S3 bucket that is enabled for anonymous public access.')
parser.add_argument('-b','--bucket',help='Main bucket on S3', required=True)
parser.add_argument('-w','--wd', help='Working directory',required=True)
args = parser.parse_args()

# Download these to the working directory specified by mywd.
os.chdir(args.wd)
conn = S3Connection(anon=True)
pth = args.bucket.split('/')
mainbucket = pth[2].split('.')[0]
objbucket = '/'.join(pth[3:len(pth)])
bkt = conn.get_bucket(mainbucket)
print("Downloading files from Amazon S3...")
for key in bkt.list(objbucket):
    mykey = key.name.encode('utf-8')
    try:
        res = key.get_contents_to_filename(mykey.split('/')[-1])
    except:
        pass
    
print("Done.")
