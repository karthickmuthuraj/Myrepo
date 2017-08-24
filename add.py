#!/usr/bin/python 
import sys,logging,argparse

LOG_FORMAT = "%(levelname)s %(asctime)s - %(message)s"
logging.basicConfig(filename="example.log",level=logging.DEBUG,format=LOG_FORMAT,filemode="w")
logger = logging.getLogger()
def get_args():
    parser = argparse.ArgumentParser(description="Find the Biggest of 3 numbers")
    parser.add_argument("-a",required=True)
    parser.add_argument("-b",required=True)
    parser.add_argument("-c",required=True)
    args = parser.parse_args()
    return args

def Twobig(a,b):
       if a > b:
          return a
       else:
          return b


def ThirdBig(a,b,c):
    big = Twobig(a,b)
    if big > c:
       return big
    else:
       return c

def main():
   logger.info("Getting Argument through parser")
   args = get_args()  
   logger.info("Started Function")
   Big = ThirdBig(args.a,args.b,args.c)
   logger.info("Printing the Biggest Number")
   print Big
   logger.info("Completed finding the biggest Number")


if  __name__ == "__main__":
   main()
