import os
import sys
import os.path, time
from time import gmtime, strftime
import datetime


dirName = sys.argv[1]

for fileName in os.listdir(dirName):
    file = os.path.join(dirName,fileName)
    if file.lower().endswith(".jpg"):
        (mode, ino, dev, nlink, uid, gid, size, atime, mtime, ctime) = os.stat(file)
        print(fileName)
        if (not fileName.startswith("PT")):
            print("No rename")
            continue
        mtime2 = datetime.datetime.fromtimestamp(mtime);
        dateStr = mtime2.strftime("%Y-%m-%d")
        newFileName = (dateStr+"_" + fileName)
        newFullFileName = os.path.join(dirName, newFileName)
        print("Rename " + file + " to " + newFileName)
        os.rename(file,newFullFileName)
        
