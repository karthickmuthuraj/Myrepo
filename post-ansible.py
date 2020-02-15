#!/usr/bin/python 
###############################################################################
# Script name : post-script.py                                                #
#     Purpose : This script intend to completed post configuration of Linux VM#
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 06/02/2020                                                    #
###############################################################################
import os,socket,sys,commands,shutil, argparse

def get_args():
    parser = argparse.ArgumentParser(description="Post build script for ansible Lab Configuration")

    parser.add_argument("-d","--devicename",required=True,help="Interfacename")
    parser.add_argument("-i","--ipaddress",required=True,help="IP address")
    parser.add_argument("-s","--servername",required=True,help="Hostname")
    parser.add_argument("-g","--gateway",required=True,help="gateway")
    parser.add_argument("-n","--dns",required=True,help="nameserver")

    args = parser.parse_args()

    return args


def precheck(servname):
   if os.getuid() != 0:
     print "Script must be executed by root"
     sys.exit(1)
   if servname == socket.gethostname():
     print "hostname is same"
     sys.exit(1)
def set_ipaddr(ipaddress,intfname,gtway,domname):
   fname="/etc/sysconfig/network-scripts/ifcfg-" + intfname
   nw_dict = {}
   with open(fname,"r") as fd:
      for line in fd:
        configparam, value = line.split("=")[0] , line.split("=")[1].strip("\n")
        nw_dict[configparam] = value 
   for param, value in nw_dict.items():
    if "IPADDR" in param or "GATEWAY" in param or "DNS1" in param or "PREFIX" in param:
        nw_dict['IPADDR'] = ipaddress
	nw_dict['PREFIX'] = "24"
	nw_dict['GATEWAY'] = gtway
	nw_dict['ONBOOT'] = "yes"
	nw_dict['DNS1'] = domname
    else:
        nw_dict['IPADDR'] = ipaddress
	nw_dict['PREFIX'] = "24"
	nw_dict['GATEWAY'] = gtway
	nw_dict['ONBOOT'] = "yes"
	nw_dict['DNS1'] = domname
    with open(fname,"w") as fdwrite:
       for param,value in nw_dict.items():
	    cline= param + "=" + value + "\n"
            fdwrite.write(cline)     		
     
def set_hostname(servname):
    oldservname=commands.getoutput("hostnamectl status").split("\n")[0].strip().split(":")[1].strip()  
    if oldservname == servname:
       print("Hostname change is not required")
    else:
       os.system("hostnamectl set-hostname " + servname)
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
              with open("/etc/selinux/config","r") as selinuxfd:
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
                     
def main():
   args = get_args()
   precheck(args.servername)
   set_ipaddr(args.ipaddress,args.devicename,args.gateway,args.dns)
   set_hostname(args.servername)
   selinuxconfig()


if  __name__ == "__main__":
   main()
