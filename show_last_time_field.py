"""
Usage: %(scriptName)s DIRNAME

Given a directory as parameter, recursively go over all log files under it, find the last "Elapsed time", print a list of files and times sorted by time
"""

import sys
import re
import os
import math
import datetime


def lastElapsedTime(fullpathfilename):
    time = "NO TIME";
    for line in open(fullpathfilename):
        m = re.search(".*Elapsed Time: ([0-9.:]+)",line)
        if (m):
            time = m.group(1)
    return time;


if len(sys.argv) < 2:
    print (__doc__ % {'scriptName' : sys.argv[0].split("\\")[-1]} )
    sys.exit(0)    


dirname = sys.argv[1]
results = []

for root, subFolders, files in os.walk(dirname):
    for file in files:
        fp = os.path.join(root, file)
        #print("Checking file" + fp + "\n")
        ext = os.path.splitext(fp)[-1].lower()
        if ext == ".log":
            time = lastElapsedTime(fp)
            if not (time == "NO TIME"):
                results.append([file,time])

results = sorted(results,key = lambda pair: pair[1])
for result in results:
    print ("File=" + result[0] + ", time=" + result[1]);