#!/usr/bin/python
new_dict = { x:y for x,y in range(2),range(10,12)) }
reverse_dict={}

for x,y in new_dict.items():
    reverse_dict[y] = x

