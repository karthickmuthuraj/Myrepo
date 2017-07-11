#!/usr/bin/env python 
# This script to check permit Root Login in /etc/ssh/sshd_config
with open("/etc/ssh/sshd_config","r") as raja:
    for line in raja:
        if "PermitRootLogin no" in line and not line.startswith("#"):
           line = line.replace("PermitRootLogin no","PermitRootLogin yes")
           raja.write(line)
        else:
            print "PermitRootLogin is enabled already"
            break

