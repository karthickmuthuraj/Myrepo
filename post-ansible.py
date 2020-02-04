#!/usr/bin/python 
###############################################################################
# Script name : post-script.py                                                #
#     Purpose : This script intend to harden of EC2 instance for Cloudera     #
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 28/06/2017                                                    #
###############################################################################
import os,socket,sys,commands,shutil, argparse

def get_args():
    parser = argparse.ArgumentParser(description="Post build script for ansible Lab Configuration")

    parser.add_argument("-d","--devicename",required=True,help="Interfacename")
    parser.add_argument("-i","--ipaddress",required=True,help="IP address")
    parser.add_argument("-s","--servername",required=True,help="Hostname")

    args = parser.parse_args()

    return args


def precheck(servname):
   if os.getuid() != 0:
     print "Script must be executed by root"
     sys.exit(1)
   if servname == socket.gethostname():
     print "hostname is same"
     sys.exit(1)

def set_hostname(servname):
    oldservname=commands.getoutput("hostnamectl status").split("\n")[0].strip().split(":")[1].strip()  
    if oldservname == servname:
       print("Hostname change is not required")
    else:
       os.system("hostnamectl set-hostname " + svrname)
       newservname=commands.getoutput("hostnamectl status").split("\n")[0].strip().split(":")[1].strip()
       if servname == newservname:
          print("Hostname" + servname + " is changed")
       else:
          print("Unable to change the hostname")

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
                     
get_args()
precheck()
set_hostname()
selinuxconfig()
