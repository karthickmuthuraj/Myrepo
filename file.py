#!/usr/bin/python 
import sys

try:
 fd=open("/root/sample.pl","r")
 for lines in fd.readlines():
     print lines.strip()
except IOError:
    print "There is an error while opening file.."  
    sys.exit()

fd.close
