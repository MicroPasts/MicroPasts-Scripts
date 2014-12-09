import Image
import os
import re

#Tokeniser function
digits = re.compile(r'(\d+)')
def tokenize(filename):
    return tuple(int(token) if match else token
                 for token, match in
                 ((fragment, digits.search(fragment))
                  for fragment in digits.split(filename)))

#The root directory to use
root = ''
#The sub folder if required
directory = root + ''
#File extension to query
extension = '.jpg'
#Are the folders arranged with front image as odd numbers?
frontfirst = True
#Rotation required 
reqrot = 90
# A new directory to put merged images into
resdir = root + 'baIndexCropped/'
#Print the directory
print('Final directory' + resdir)
# cropped images 
croppedDir = root + 'baIndexResized/'
print('Cropped directory' + croppedDir)
#Create directory if not there
if not os.path.exists(resdir):
    os.makedirs(resdir)
if not os.path.exists(croppedDir):
    os.makedirs(croppedDir)
#Sort the file list
for subdir, dirs, files in os.walk(directory):
    print('Sub directory' + subdir)
    files = [file for file in os.listdir(subdir) if file.lower().endswith(extension)]
    files.sort(key=tokenize)
    #Create the arrays
    if frontfirst:
       cardfronts = files[::2]
       cardbacks = files[1::2]
    else:
       cardfronts = files[1::2]
       cardbacks = files[::2]

    #Loop through both arrays
    for f, b in zip(cardfronts, cardbacks):
       imf = Image.open(os.path.join(subdir, f))
       imb = Image.open(os.path.join(subdir, b))
    
       #Work out maximum width
       maxwd = max(imf.size[0],(imb.size[0]))
       print(imb.size)
       box = (0,0, imb.size[0], imb.size[1]/2)
       var1, var2 = f.split(".")
       var3, var4 = b.split(".")

       filename = croppedDir + var3 + extension
       print('Final file name:' +  filename)
       output = imb.crop(box).save(filename)
       imc = Image.open(filename)
       #Add heights together
       sumht = imf.size[1] + imc.size[1]
       #Create new image
       imnew = Image.new('RGB', (maxwd,sumht), 'black')
       #Paste them back together
       imnew.paste(imf, (0,0))
       imnew.paste(imc, (0,imf.size[1]))
       #Save new image
       newImage = resdir + var1 + '_' + var3 + '_final' + extension
       imnew.save(newImage)
       print('Image path' + newImage)
