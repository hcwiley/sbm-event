import os, sys
from glob import glob
os.chdir(sys.argv[1])
for f in glob("*.*"):
  file = open(f.lower().replace(".jpg",".txt"), "w+")
  file.write("hello world. <strong>i'm bold text</strong>. <italic>i'm italics text</italic>")
  file.flush()
  file.close()
  os.rename(f, "%s" % f.lower())
