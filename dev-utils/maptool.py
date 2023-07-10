# Converts a bmp image exported from GIMP to abelon/utilities/tmp_layout.bmp
# to a mapfile grid and writes it to tmp_map.txt

import sys
from PIL import Image
from os import listdir
from os.path import isfile, join

# Mapping from colors to tile indices
mapping = {
    (0, 0, 0):        1,
    (100, 100, 100):  2,
    (200, 200, 200):  3,
    (255, 0, 0):      4,
    (150, 0, 0):      5,
    (0, 255, 0):      6,
    (0, 150, 0):      7,
    (0, 0, 255):      8,
    (0, 0, 150):      9,
    (255, 255, 0):   'A',
    (150, 150, 0):   'B',
    (255, 0, 255):   'C',
    (150, 0, 150):   'D',
    (0, 255, 255):   'E',
    (0, 150, 150):   'F',
    (255, 255, 255): 'G',
    (255, 200, 200): 'H',
    (200, 255, 200): 'I',
    (200, 200, 255): 'J',
    (255, 100, 0):   'K',
    (100, 0, 255):   'L',
    (0, 255, 100):   'M',

    # Not yet added
    (4, 4, 4):   'N',
    (5, 5, 5):   'O',
    (6, 6, 6):   'P',
    (7, 7, 7):   'Q',
    (8, 8, 8):   'R',
    (9, 9, 9):   'S',
    (1, 1, 1):   'T',
    (2, 2, 2):   'U',
    (3, 3, 3):   'V',
    (1, 2, 3):   'W',
}

# Read bmp file specified on the command line and write tile numbers to a
# file according to pixel colors
if len(sys.argv) != 2:
    print("Usage: python3 abelon/utilities/maptool.py destination-dir")
    exit(1)
pth = 'abelon/dev-utils'
fs = [ join(pth, f) for f in listdir(pth) if isfile(join(pth, f)) and f[-4:] == '.bmp' ]
im = Image.open(fs[0])
pix = im.load()
w, h = im.size
with open('abelon/data/maps/' + sys.argv[1] + '/map.txt', 'w') as map_file:
    for y in range(h):
        for x in range(w):
            pixel = pix[x,y]
            map_file.write(str(mapping[pixel]))
        map_file.write("\n")