#!/usr/bin/python
## Split audio files into chunks
## Daniel Pett 1/5/2020
__author__ = 'portableant'
## Tested on Python 2.7.13

import argparse
import os
import speech_recognition as sr
r = sr.Recognizer()
parser = argparse.ArgumentParser(description='A script for splitting audio files into segements')
parser.add_argument('-p', '--path', help='The path to the folder to process', required=True)

# Parse arguments
args = parser.parse_args()
path = args.path

# Loop through the files
for file in os.listdir(path):
    print('Now processing: ' + file)
    with sr.AudioFile(path + file) as source:
      # listen for the data (load audio to memory)
      audio_data = r.record(source)
      # recognize (convert from speech to text)
      text = r.recognize_google(audio_data)
      print(file + ',' + text")
