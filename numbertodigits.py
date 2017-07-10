#!/usr/bin/python
import commands

n=int(raw_input("Enter the number:"))

single={1:"One", 2:"Two",3:"Three",4:"Four",5:"Five",6:"Six",7:"Seven",8:"Eight",9:"Nine",0:"Zero"}

teen={11:"Eleven",12:"Twelve",13:"Thirteen",14:"Fourteen",15:"Fifteen",16:"Sixteen",17:"Seventeen",18:"Eighteen",19:"Nineteen"}

if n>=0 and n<=9:
   print single[n]
elif n>=11 and n<=19:
   print teen[n]
else: 
   print "Number out of range"
