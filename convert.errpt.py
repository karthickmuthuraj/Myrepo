#!/usr/bin/python 
import sys
if len(sys.argv) < 3:
   print "script usage wrong: scriptname <source file> <destination file>"
   sys.exit

with open(sys.argv[1],"r") as errptfd:
   with open("errpt.1","w") as errfd:
      for line in errptfd:
         line=line.strip().split()
         x = ",".join(line[0:5]) + ","
         y = " ".join(line[5:])
         if x.startswith("IDENTIFIER"): 
            x = x + y + "," + "HOSTNAME" + "\n"
            errfd.write(x)
         else:
            x = x + y + "," + sys.argv[2] + "\n"
            errfd.write(x)
