import subprocess
import os
import time
import ICP_detect
import datetime


while True:
        # Read in last alert times
        with open('alert_log.txt') as f:
                alert_times = [line.rstrip('\n') for line in f]
        
        
        startTime = datetime.datetime.nio() - datetime.timedelta(seconds=30) -  datetime.timedelta(minutes=20)
        
        ICP_detect.main(startTime,alert_times)
        
        print('Analyzed up to ' + str(startTime))
        time.sleep(60)
        #startTime = startTime + datetime.timedelta(minutes=5)