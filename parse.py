#!/usr/bin/python
import argparse

parser = argparse.ArgumentParser(description="Filesystem addition/Extend the size")
parser.add_argument("-f",help="File System Name")
parser.add_argument("-s",help="File System Size")
parser.add_argument("-i",help="SCSI ID")
args = parser.parse_args()
import pdb 
pdb.set_trace()


print args.f
