#!/usr/bin/python 

import commands 

df_output = commands.getoutput("df -k")

df_output = df_output.split("\n")

for fields in df_output:
         ufield=fields.split()[4].strip("%")
         if ufield != "Use" and int(ufield) >= 15:
                 print "File System name:%s" %fields.split()[5]
