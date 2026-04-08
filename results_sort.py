import sys
import collections
import operator
import functools

blocks = [['*** General Queries Hash ***','-----'],['*** Results Summary ***','-----'],['----------------General Queries Summary--','--End General Queries Summary---']]
in_block = False;
outputlist = []
sortedlist = []

if len(sys.argv) <2:
   print('Usage: ' + sys.argv[0] + ' inputfile [outputfile]')
   exit() 

fname = sys.argv[1]
if len(sys.argv) > 2:
    outputfname = sys.argv[2]
else:
    outputfname = fname.replace(".log","_sorted.log")

fileContent = [line.strip() for line in open(fname)]

for line in fileContent:
    for blk in blocks: # Go over all pairs and look for start/finish
        if (not in_block and (blk[0] in line)):
            in_block = blk;                     # Found trigger: Started block
        if in_block and in_block[1] in line:    # Found end, finish block
            in_block = None;            
            outputlist.extend(sorted(sortedlist))
            sortedlist = []
    if in_block:
        sortedlist.append(line)
    else:
        #outputlist.append(line)
        pass

outputlist.extend(sorted(sortedlist))

f = open(outputfname, 'w')
for line in outputlist:
    f.write(line + '\r\n')
    