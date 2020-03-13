#!/usr/bin/python
import commands, sys, os, socket

def sysinfo():
   servername = os.uname()
   servername = servername[0]
   if servername == 'Linux':
        print "Linux"


def main():

   if len(sys.argv) < 3: 
       print "Script Usage wrong: <script name> <FS NAME> <FS SIZE> <SCSI ID>"
       sys.exit(1)
   sysinfo()

if __name__ == "__main__": 
 main()
