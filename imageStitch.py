import Image
import os

directory = '.'
extension = '.jpg'
frontfirst = True
reqrot = 90
resdir = './rotated/'

files = [file for file in os.listdir(directory) if file.lower().endswith(extension)]
if frontfirst:
    cardfronts = files[::2]
    cardbacks = files[1::2]
else:
    cardfronts = files[1::2]
    cardbacks = files[::2]

for f in cardfronts:
    for b in cardbacks:
        imf = Image.open(os.path.join(directory, f))
        imb = Image.open(os.path.join(directory, b))
        imf = imf.rotate(reqrot)
        imb = imb.rotate(reqrot)
        maxwd = max(imf.size[0],(imb.size[0]))
        sumht = imf.size[1] + imb.size[1]
        imnew = Image.new('RGB', (maxwd,sumht), 'black')
        imnew.paste(imf, (0,0))
        imnew.paste(imb, (0,imf.size[1]))
        var1, var2 = f.split(".")
        imnew.save(resdir + var1 + '_fb.jpg')
