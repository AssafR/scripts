import sys
import re

fname = sys.argv[1];
print(fname)
f = open(fname, 'r')
for line in f:
        #m = re.search(line,'.*([.].*)$');
        xline = re.sub('.*[.]','XXX',line);
        print(xline)
        #if (m!=None):
        #        print(m.group(0));
        