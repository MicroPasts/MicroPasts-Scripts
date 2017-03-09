from PIL import Image
import os
import re

#Tokeniser function
digits = re.compile(r'(\d+)')
def tokenize(filename):
    return tuple(int(token) if match else token
                 for token, match in
                 ((fragment, digits.search(fragment))
                  for fragment in digits.split(filename)))


root = '/Users/danielpett/Documents/'
directory = root + 'postcards/'
extension = '.jpg'
# A new directory to put merged images into
resdir = root + 'new/'
#Create directory if not there
if not os.path.exists(resdir):
    os.makedirs(resdir)

for root, dirs, files in os.walk(directory):
    for i in dirs:
        filename = i
        for files in os.walk(os.path.join(directory,i)):
            print(files[2][1])
            imgA = Image.open(os.path.join(directory, files[0], files[2][0]))
            imgB = Image.open(os.path.join(directory, files[0], files[2][1]))
            #Work out maximum width
            maxwd = max(imgA.size[0],(imgB.size[0]))
            #Add heights together
            sumht = imgA.size[1] + imgB.size[1]
            #Create new image
            imnew = Image.new('RGB', (maxwd,sumht), 'black')
            #Paste them back together
            imnew.paste(imgB, (0,0))
            imnew.paste(imgA, (0,imgB.size[1]))
            #Save new image
            imnew.save(resdir + i + extension)

