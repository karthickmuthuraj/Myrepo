#!/usr/bin/python 
import commands


passwd_file = commands.getoutput("cat /etc/passwd")


passwd_file = passwd_file.split("\n")

passwd_list=[]
for line in passwd_file: 
       line = line.split(":")
       passwd_list.append([line[0],line[2:]])
       
print passwd_list
