#!/usr/bin/env python 
###############################################################################
# Script name : get argument details                                          #
#     Purpose : Get Argument for adding the file system                       #
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 17/08/2017                                                    #
###############################################################################
import argparse

def get_args():
    parser = argparse.ArgumentParser(description="Filesystem addition/Extend the size")

    parser.add_argument("-f","--fsname",required=True,help="File System Name")
    parser.add_argument("-s","--size",required=True,help="File System Size")
    parser.add_argument("-i","--id",required=True,help="SCSI-ID")

    args = parser.parse_args()

    return args


def main():
  args= get_args() 
  print args.fsname,args.size,args.id



if  __name__ == "__main__":
   main()
