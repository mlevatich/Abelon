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
        add = lambda s: print("~{} {} {} {}".format(s, j + 1, i + 1, 'L' if LR else 'R'))
        if grid[i][j] not in colliding:
            if   random() <= 0.100: add("grass2")
            elif random() <= 0.050: add("grass")
            elif random() <= 0.020: add("rock")
            elif random() <= 0.018: add("shafe")
            elif random() <= 0.018: add("forniese")
            elif random() <= 0.008: add("colblossom")
            LR = not LR