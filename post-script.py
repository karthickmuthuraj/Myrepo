#!/usr/bin/python 
###############################################################################
# Script name : post-script.py                                                #
#     Purpose : This script intend to harden of EC2 instance for Cloudera     #
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 28/06/2017                                                    #
###############################################################################
import os,socket,sys,commands

def precheck():

   if os.getuid() != 0:
     print "Script must be executed by root"
     sys.exit(1)
   if len(sys.argv) < 2:
     print "script usage wrong:python scriptname <hostname>"
     sys.exit(1)
   if sys.argv[1] == socket.gethostname():
     print "hostname is same"
     sys.exit(1)
def set_hostname():
   with open("/etc/hostname","w") as hostf:
        hostf.write(sys.argv[1])
   with open("/etc/sysconfig/network","a") as nhostf:
        nhostf.write("HOSTNAME="+ sys.argv[1])


def selinuxconfig():

     selinuxstat = commands.getoutput("/usr/sbin/sestatus")
     selinuxstat = selinuxstat.split("\n")
     for fields in selinuxstat:
         if fields.split(":")[0].strip().startswith("SELinux") and fields.split(":")[1].strip() == "enabled":
               with open("/etc/selinux/config","rw+") as selinuxfd:
                   for line in selinuxfd:
                     if line.find("SELINUX=enforcing"):
                        setselinux=line.replace("SELINUX=enforcing","SELINUX=disabled")
                        line.write(setselinux) 
                     
precheck()
set_hostname()
selinuxconfig()
