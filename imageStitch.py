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


root = ''
directory = root + ''
extension = '.jpg'
#Are the folders arranged with front image as odd numbers?
frontfirst = True
#Rotation required 
reqrot = 90
# A new directory to put merged images into
resdir = directory + '/new/'
#Create directory if not there
if not os.path.exists(resdir):
    os.makedirs(resdir)

#Sort the file list
files = [file for file in os.listdir(directory) if file.lower().endswith(extension)]
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
    imf = Image.open(os.path.join(directory, f))
    imb = Image.open(os.path.join(directory, b))
    #rotate the images
    imf = imf.rotate(reqrot)
    imb = imb.rotate(reqrot)
    
    #Work out maximum width
    maxwd = max(imf.size[0],(imb.size[0]))
    #Add heights together
    sumht = imf.size[1] + imb.size[1]
    #Create new image
    imnew = Image.new('RGB', (maxwd,sumht), 'black')
    #Paste them back together
    imnew.paste(imf, (0,0))
    imnew.paste(imb, (0,imf.size[1]))
    #Split file names up
    var1, var2 = f.split(".")
    var3, var4 = b.split(".")
    #Save new image
    imnew.save(resdir + var1 + '_' + var3 + '_fb' + extension)
