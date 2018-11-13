#!/usr/bin/env python

from __future__ import print_function
__metaclass__ = type

import sys
sys.path.append('/etc/easydr/site-packages')

import time
from easydr_tools import MyThread
from parser_configfile import *
from handler_dr import Handler_dr
from handler_vi import Handler_vi

if __name__ == "__main__":
    try:
        while True:
            time.sleep(2)
            task_handler_dr = MyThread(Handler_dr, (debug_dr, musers_dr, mpks))
            task_handler_vi = MyThread(Handler_vi, (debug_vi,musers_vi))

            threads = []
            threads.append(task_handler_dr)
            threads.append(task_handler_vi)
	    for thread in threads:	        
	        thread.start()
	    for thread in threads:	        
	        thread.join()
    except KeyboardInterrupt:
        sys.exit()
