#!/usr/bin/python
import logging

LOG_FORMAT = "%(levelname)s %(asctime)s - %(message)s"
logging.basicConfig(filename="example.log",level=logging.DEBUG,format=LOG_FORMAT,filemode="w")
logger = logging.getLogger()
logger.info("Our First Message")
