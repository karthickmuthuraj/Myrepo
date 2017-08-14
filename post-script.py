#!/usr/bin/python 
###############################################################################
# Script name : post-script.py                                                #
#     Purpose : This script intend to harden of EC2 instance for Cloudera     #
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 28/06/2017                                                    #
###############################################################################
import os,socket,sys,commands,shutil

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
              with open("/tmp/selinux_config","r") as selinuxfd:
                  with open("/tmp/selinux.new","w") as newselinuxfd:
                      for line in selinuxfd:
                          if "SELINUX=enforcing" in line:
                              setselinux=line.replace("SELINUX=enforcing","SELINUX=disabled")
                              newselinuxfd.write(setselinux)
                          else:
                              newselinuxfd.write(line)
     if os.path.isfile("/tmp/selinux.new"):
           shutil.copy2("/tmp/selinux.new","/etc/selinux/config")
           os.chmod("/etc/selinux/config",644)
           print("SELINUX is disabled. It required reboot")
     else:
        print "File does not exists" 
                     
precheck()
set_hostname()
selinuxconfig()
