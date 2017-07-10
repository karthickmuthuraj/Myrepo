#!/usr/bin/python
import commands 

def main():
   username = commands.getoutput("cat /etc/passwd")

   username = username.split("\n")

   for user in username: 
      if user.split(":")[2] > 200: 
         print user.split(":")[0]

main()
