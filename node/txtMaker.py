import os, sys
from glob import glob
os.chdir(sys.argv[1])
imageTypes = ("*.png", "*.PNG", "*.jpg",
        "*.JPG", "*.jpeg", "*.JPEG")
files_grabbed = []
for files in imageTypes:
    files_grabbed.extend(glob(files))
for f in files_grabbed:
  fType = f.split(".")
  fType = fType[len(fType) - 1]
  file = open(f.replace(fType, "txt"), "w+")
  #file.write("hello world. <strong>i'm bold text</strong>. <italic>i'm italics text</italic>")
  #file.flush()
  #file.close()
  os.rename(f, "%s" )#% f.lower())
