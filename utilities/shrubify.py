# Reads a map file into a grid, and outputs a placement of grass and grass2 
# onto random non-colliding tiles

import sys
from random import random

if len(sys.argv) != 2:
    print("Usage: python3 abelon/utilities/shrubify.py map-directory")
    exit(1)

prefix = 'abelon/data/maps/' + sys.argv[1]
mapfile = prefix + '/map.txt'
metafile = prefix + '/meta.txt'

colliding = None
with open(metafile, 'r') as f:
    colliding = f.readlines()[4]

grid = None
with open('abelon/data/maps/' + sys.argv[1] + '/map.txt', 'r') as f:
    grid = f.readlines()

LR = True
for i in range(len(grid)):
    for j in range(len(grid[i])):
        if grid[i][j] not in colliding:
            if random() <= 0.1:
                print("~grass2 {} {} {}".format(j + 1, i + 1, 'L' if LR else 'R'))
            elif random() <= 0.05:
                print("~grass {} {} {}".format(j + 1, i + 1, 'L' if LR else 'R'))
            LR = not LR