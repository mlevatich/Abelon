# Converts a bmp image exported from GIMP to abelon/utilities/tmp_layout.bmp
# to a mapfile grid and writes it to tmp_map.txt

import sys
from PIL import Image

# Mapping from colors to tile indices
mapping = {
    (0, 0, 0):        1,
    (100, 100, 100):  2,
    (200, 200, 200):  3,
    (255, 0, 0):      4,
    (0, 0, 150):      5,
    (0, 255, 0):      6,
    (0, 150, 0):      7,
    (0, 0, 255):      8,
    (150, 0, 0):      9,
    (255, 255, 0):   'A',
    (150, 150, 0):   'B',
    (255, 0, 255):   'C',
    (150, 0, 150):   'D',
    (0, 255, 255):   'E',
    (0, 150, 150):   'F',
    (255, 255, 255): 'G',
}

# Read bmp file specified on the command line and write tile numbers to a
# file according to pixel colors
if len(sys.argv) != 2:
    print("Usage: python3 maptool.py layout.bmp")
    exit(1)
im = Image.open(sys.argv[1])
pix = im.load()
w, h = im.size
with open('map.txt', 'w') as map_file:
    map_file.write(str(w) + ' ' + str(h))
    map_file.write("\n")
    for y in range(h):
        for x in range(w):
            pixel = pix[x,y]
            map_file.write(str(mapping[pixel]))
        map_file.write("\n")
