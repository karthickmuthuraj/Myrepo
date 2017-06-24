#!/usr/bin/python

numbers = [ 65,87,20,10,56,92,43,95 ]
big=0
for number in numbers:
    if number >= big:
        big=number


print "The Biggest number in the list: %s" % big
