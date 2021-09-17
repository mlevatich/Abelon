# Converts a bmp image exported from GIMP to abelon/utilities/tmp_layout.bmp
# to a mapfile grid and writes it to tmp_map.txt

import sys

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

# Read bmp file into list of rows of pixels
def getRows(path, width, height):

    # Open image and skip header
    img = open(path, "rb")
    img.seek(122)

    # Read pixels from file, row by row
    pos = 0
    rows = []
    row = []
    while True:

        # Reached end of row
        if pos == width:

            # Add new row, check if done
            rows.insert(0, row)
            if len(rows) == height:
                break

            # Reset
            pos = 0
            row = []

        # Read three bytes
        b = ord(img.read(1))
        g = ord(img.read(1))
        r = ord(img.read(1))

        # Add tuple to current row
        row.append((r, g, b))
        pos += 1

    # Close image and return rows
    img.close()

    return rows

# Make new mapfile from pixel rows
def writeMapfile(rgb_rows):

    # Open new mapfile
    map_file = open("tmp_map.txt", "w")

    # Iterate over each row
    for row in rgb_rows:
        for pixel in row:

            # Write the tile corresponding to this pixel's color
            if not mapping[pixel]:
                print("Error: Found a pixel which is not in the color mapping")
                exit()
            map_file.write(str(mapping[pixel]))

        # Newline at the end of each row
        map_file.write("\n")

    # Close file
    map_file.close()

# Read bmp file specified on the command line and write tile numbers to a file according to pixel colors
def main():

    # Check usage
    if len(sys.argv) != 3:
        print("Usage: python3 maptool.py width height")
        return
    try:
        w = int(sys.argv[1])
        assert(w % 4 == 0)
        h = int(sys.argv[2])
        assert(h % 4 == 0)
    except:
        print("Error: width and height must be integers divisible by four")
        return

    # Read rows
    rows = getRows("tmp_layout.bmp", w, h)

    # Make map file
    writeMapfile(rows)

# Entry point
if __name__ == "__main__":
    main()
