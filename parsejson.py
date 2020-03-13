#!/usr/bin/python 
###############################################################################
# Script name : parsejson.py                                                  #
#     Purpose : Parse json file and convert into dictionary and print values  #
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 04/04/2018                                                    #
###############################################################################
import argparse,json 

parser = argparse.ArgumentParser(description="JSON Parser")
parser.add_argument("-f",help="File Name")

args = parser.parse_args()

with open(args.f,"r") as fd: 
    distros_dict = json.load(fd)

for distro in distros_dict:
   print distro['Name']
