#Notes and Usage

These are scripts for manipulating the crowdsourced transcription data to extract a list of people to credit for a given taks (e.g. if each task has been done more than once).

photomask_credits.R -- A set of example R commands that are currently run locally on an example set of photomasking tasks, so paths need to be changed. Also, this script will only work if you have admin access to contributor's full names (not publicly downloadable). The workflow extract all unique authenticated full user names associated a given 3D model (so multiple tasks associated with, for example, phtoographs of a single object). It then prints them to console where they can, for example, be copied and pasted into a metadata file associated with the final 3D model.

