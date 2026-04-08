import sys
import re
import os
import math
import datetime

def parseHHMM(timestr):
  h,m,s = re.split(':',timestr)

  li = re.split('[.]', s)   # Fix problem of extra '.' at the end
  s = li[0] + '.' + li[1]   # -----------------------------------

  mili,s = math.modf(float(s))
  mili = 1000*mili
  return int(h),int(m),int(s),mili

def timeAsSeconds(item):
  h,m,s,mili = parseHHMM(item)
  dt = datetime.timedelta(hours=h,minutes=m,seconds=s,milliseconds=int(mili)).total_seconds()
  return dt

def stat(fullpathfilename):
    dir, name = os.path.split(fullpathfilename)
    m = re.match("[0-9T\-_]+(.*).log", name)
    if m:
        projname = m.groups(0)[0]
        
    fileContent = [re.match(".*Queries part Duration: ([0-9\:\.]*).*", line).groups(0)[0] for line in open(fullpathfilename) if re.match(".*Queries part Duration: ([0-9\:\.]*).*", line)]
    time = 'No Time' if (len(fileContent)==0) else timeAsSeconds(fileContent[-1])
    return projname,time

     
fname = sys.argv[1]
dirname = sys.argv[1]

for root, subFolders, files in os.walk(dirname):
    for fp in files:
        ext = os.path.splitext(fp)[-1].lower()
        if ext == ".log":
            print(stat(root+'\\' + fp))
