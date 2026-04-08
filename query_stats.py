import sys
import collections
import operator
import functools

fname = sys.argv[1]

# Read file, line by line
fileContent = [line.strip() for line in open(fname)]

myDict = collections.defaultdict(list)  # init a dictionary whose default value constructor is one of a list.
    
for line in fileContent:
  if ("DefaultQuery" in line or not line.endswith(".cxq")):
    continue;
  line = line.replace(".cxq","")
  split_dir = line.split('\\')          # Split full file name to list of subdirs
  split_dir.reverse()                   # Easier: Filename is now first, language is last
  key = split_dir[0]                    # First (last) item is the query name
  myDict[key].append(split_dir);        # For each key (=filename=query), a list of items, each item is a list with all the filename/directory for one filename.

sortedQueryList = list();
for query in myDict.keys():
  size = len(myDict[query])                 # Number of languages
  sortedQueryList.append([query, size]);    # Each element array of size 2.

sortedQueryList.sort(key= lambda x: x[1], reverse=True) # Sort by second element (size)

for key in sortedQueryList:
  dirs  = myDict[key[0]]
  langs = (lang[-1:1:-1] for lang in dirs)     # Collect last element from all lists (language name)
  langs = functools.reduce(operator.add,langs) # Flatten the list of lists of lists
  print(key+langs)
  