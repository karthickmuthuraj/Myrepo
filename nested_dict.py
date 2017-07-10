#!/usr/bin/python 
import commands

passwd_output= commands.getoutput("cat /etc/passwd")

passwd_output = passwd_output.split("\n")

new_dict={}
fields=[]
for line in passwd_output:
       fields= line.split(":")
       new_dict[fields[0]]={fields[2]:fields[6]}

for x,y in new_dict.items():
    for i,j in y.items():
       if i>100 and j=="/bin/bash":
          print x

