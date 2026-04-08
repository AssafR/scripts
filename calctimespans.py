import sys
import collections
import operator
import functools
import re
import datetime
import math

def parseHHMM(timestr):
  h,m,s = re.split(':',item)  
  mili,s = math.modf(float(s))
  mili = 1000*mili
  return int(h),int(m),int(s),mili

def timeAsSeconds(item):
  h,m,s,mili = parseHHMM(item)
  dt = datetime.timedelta(hours=h,minutes=m,seconds=s,milliseconds=int(mili)).total_seconds()
  return dt

  
fname = sys.argv[1]
fileContent = [line.strip() for line in open(fname)]
dateRe = "[0-9][0-9]/[0-9][0-9]/[0-9][0-9]/ [0-9][0-9][:][0-9][0-9][:][0-9][0-9]"

res = []
for item in fileContent:
  m = re.match("30/11/2015 17:05:41", item)
  if m:
    res.extend(m.groups(0))

sum=0;    
for item in res:
  dt = timeAsSeconds(item)
  sum += dt;
  print(dt)
  
print("Sum=",sum)
