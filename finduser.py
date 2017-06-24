#!/usr/bin/python
import commands 

username = commands.getoutput("cat /etc/passwd")

username = username.split("\n")

for user in username: 
   if user.split(":")[2] > 50: 
      print user.split(":")[0]
