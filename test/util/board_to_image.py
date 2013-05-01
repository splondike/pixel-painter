#!/usr/bin/env python

# Turns a saved board into a screenshot

import sys, os

SAVE_IGNORE_LINES = 4
PIXEL_COLOUR = {
   "1": "255 119 34",
   "2": "255 255 102",
   "3": "119 204 51",
   "4": "102 170 255",
   "5": "51 68 255",
   "6": "51 51 51",
}

if len(sys.argv) != 3:
   print("Usage: draw-board.py <board.save> <out.ppm>")
   sys.exit(1)


# Deserialize the board to a python array
board = []
save = open(sys.argv[1], 'r')
line_count = 1
for line in save.readlines():
   if line_count <= SAVE_IGNORE_LINES:
      line_count = line_count + 1
      continue

   board.append([colour.strip() for colour in line.split(" ") if colour.strip() != ""])
save.close()

image = open(sys.argv[2], 'w')
image.write("P3\n%s\n%s\n%s\n"%(len(board), len(board), 255))
for row in board:
   for cell in row:
      image.write(PIXEL_COLOUR[cell] + "\n")
image.close()

# Scale it to a better size
os.execv("/usr/bin/mogrify", ["/usr/bin/mogrify", "-scale", "1600%", sys.argv[2]])
