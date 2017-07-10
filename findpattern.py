#!/usr/bin/python

sentence = raw_input("Please provide the string")

word = raw_input("Please provide the pattern to search")


if word in sentence: 
     print "The %s word exist in the given sentence" %word
else:
     print "The %s word not exist in the given sentence" %word
