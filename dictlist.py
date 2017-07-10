#!/usr/bin/python 
import commands


passwd_file = commands.getoutput("cat /etc/passwd")


passwd_file = passwd_file.split("\n")

passwd_dict={}
for line in passwd_file: 
       line = line.split(":")
       
       passwd_dict[line[0]] = line[2:]


print passwd_dict
