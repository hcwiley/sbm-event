import os, sys, Image, shutil
from glob import glob
os.chdir(sys.argv[1])
for f in glob("*.jpg"):
  img = Image.open(f)
  if img.size[0] >= 1024:
    shutil.copyfile("%s" % f, "../heroes/%s" % f)
