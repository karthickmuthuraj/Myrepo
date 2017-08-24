#!/usr/bin/python 
###############################################################################
# Script name : diskaddition.py                                               #
#     Purpose : Add disk and extend the file system in VM                     #
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 01/05/2017                                                    #
###############################################################################
import os, sys, commands, argparse, logging

def get_args():
     parser = argparse.ArgumentParser(description="Adding Disk and extend the filesystem in Linux VM")
     parser.add_argument("-f",required=True,help="File System Name")
     parser.add_argument("-s",required=True,help="File System Size")
     parser.add_argument("-i",required=True,help="SCSI ID")
     args = parser.parse_args()
     return args


def extendFS(fsname,fssize,scsiID):
    df_output = commands.getoutput("df -k")
    df_output = df_output.split("\n")
    scsiIds = commands.getoutput("lsscsi")
    scsiIds = scsiIds.split("\n")
    for dfFields in df_output:
       if fsname in dfFields:
         logicalname = dfFields.split()[0]
    lvName = logicalname.split("-")[1]
    vgname = commands.getoutput("vgs --noheadings 2>/dev/null")
    vgname = vgname.split("\n")
    for i in vgname:
        if not "cl" in i:
            vgName=i.split()[0]
    for id in scsiIds:
           if scsiID in id: 
              disk = id.split()[5] 
    print "LVNAME:%s VGNAME:%s DISK:%s" %(lvName,vgName,disk)

def createFS():
    pass 

def main():
  args = get_args()
  fstype=commands.getoutput("df -T /")
  fstype = fstype.split("\n")
  for fields in fstype:
         fstype = fields.split()[1]
  if commands.getoutput("dmidecode -s system-product-name") != "VirtualBox" and os.getuid !=0 and fstype == "xfs" or fstype == "ext3" or fstype == "ext4":
     sys.exit 
  
  else:
     extendFS(args.f,args.s,args.i)

if __name__ == "__main__":
   main()
