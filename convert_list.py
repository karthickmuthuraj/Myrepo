#!/usr/bin/python 
def raj_to_list(x):
     for i in x:
      if 'list' not in str(type(i)):
       print(i)
      else:
       raj_to_list(i)

