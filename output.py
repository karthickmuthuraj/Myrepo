#!/usr/bin/python 
import commands 

df_output = commands.getoutput("df -h")

df_output = df_output.split("\n")

for df_fields in df_output:
 if df_fields.split()[4].strip('%') > 30:
  print df_fields


