import pandas as pd
import numpy as np
import datetime
import sys
import subprocess
from dateutil.parser import parse
import time

def write_alert_times(alert_times):
        with open('alert_log.txt','w') as g:
                g.writelines(str(time)+'\n' for time in alert_times)

def main(startTime,alert_times):
        t = time.time()
        f = pd.HDFStore('../patient_data_' + ptName +'.h5',mode='r')


#Load the last 15 minutes for analysis

        idx = f.select_column('ICP','index')
        ICP = f.select('ICP',where=idx[(idx>startTime) & (idx<=startTime+datetime.timedelta(minutes=15))].index)

        idx = f.select_column('IC1','index')
        BOX = f.select('IC1',where=idx[(idx>startTime) & (idx<=startTime+datetime.timedelta(minutes=15))].index)
        #BOX = df = pd.DataFrame(np.random.randn(6,1),index=pd.date_range('20130101',periods=6),columns=list('A'))

        patient_name = f['name'][0][0]
        #for now, using the fake cureatr we will use a fake name. Take this out for real use
        patient_name = 'Test Patient'
        f.close()
        
# if there are at least a certain number of points and we see what we want
        highICP = False
        lowICP = False
        O2drop = False  

        highTimeStart = startTime + datetime.timedelta(minutes=10)
        highTimeEnd = highTimeStart + datetime.timedelta(minutes=5)
        lowTimeStart = startTime
        lowTimeEnd = lowTimeStart + datetime.timedelta(minutes=15)

        if len(ICP.loc[highTimeStart:highTimeEnd]) >= 5000 and np.mean(ICP[highTimeStart:highTimeEnd])[0] > 40:
                highICP = True
        if len(ICP.loc[lowTimeStart:lowTimeEnd]) >= 15000 and np.mean(ICP[lowTimeStart:lowTimeEnd])[0] > 20:
                lowICP = True
        
        if len(BOX.loc[lowTimeStart:lowTimeEnd]) >= 15000 and np.mean(BOX[lowTimeStart:lowTimeEnd])[0] < 15 and np.mean(BOX[lowTimeStart:lowTimeEnd])[0] > 0:
                O2drop = True 

        print(len(ICP.loc[highTimeStart:highTimeEnd]))
        print(np.mean(ICP[highTimeStart:highTimeEnd])[0])       
        last_low = parse(alert_times[0])
        last_med = parse(alert_times[1])
        last_high = parse(alert_times[2])
        
        if (highICP or lowICP) and O2drop:
                meanO2 = np.mean(BOX[lowTimeStart:lowTimeEnd])[0]
                if highICP:
                        meanICP = np.mean(ICP[highTimeStart:highTimeEnd])[0]
                else:
                        meanICP = np.mean(ICP[lowTimeStart:lowTimeEnd])[0]

                if divmod((highTimeEnd-last_high).total_seconds(),60)[0]>10:
                       subprocess.call('curl -k -u $USER_ID:$PASSWD https://api.play.cureatr.com/api/2014-08-01/thread/create -d subject="HIGH ALERT" -d patient_name="' + patient_name + '" -d message="Patient has elevated ICP (' + str(meanICP) + 'mmHg) and a decrease in brain oxygenation (' + str(np.mean(BOX[lowTime:lowTimeEnd])[0]) + 'mmHg) as of ' + highTimeEnd.strftime("%I:%M%p on %B %d, %Y") + '" -d recipients=steven.baldassano@uphs.upenn.edu',shell=True)#post to cureatr
                        alert_times[2] = highTimeEnd
                        write_alert_times(alert_times)
                        with open('notification_log.txt','a') as log:
                                log.write('High alert at ' +  highTimeEnd.strftime("%I:%M%p on %B %d, %Y") + 'with meanICP of ' + str(meanICP) + 'and meanPbO2 of ' + str(meanO2) + '\n')
        
        
        elif highICP:
                meanICP = np.mean(ICP[highTimeStart:highTimeEnd])[0]
                if divmod((highTimeEnd-max(last_high,last_med)).total_seconds(),60)[0]>30: # if at least 5 mins since last high or medium alarm
                       subprocess.call('curl -k -u $USER_ID:$PASSWD https://api.play.cureatr.com/api/2014-08-01/thread/create -d subject="Elevated ICP" -d patient_name="' + patient_name + '" -d message="Patient has ICP>40mmHg as of ' + highTimeEnd.strftime("%I:%M%p on %B %d, %Y") + '" -d recipients=steven.baldassano@uphs.upenn.edu',shell=True)#post to cureatr
                        alert_times[1] = highTimeEnd
                        write_alert_times(alert_times)
                        with open('notification_log.txt','a') as log:
                                log.write('Medium alert at ' +  highTimeEnd.strftime("%I:%M%p on %B %d, %Y") + 'with meanICP of ' + str(meanICP) +'\n')

        elif lowICP:
                meanICP = np.mean(ICP[lowTimeStart:lowTimeEnd])[0]
                if divmod((lowTimeEnd-max(last_high,last_med,last_low)).total_seconds(),60)[0]>30:
                        subprocess.call('curl -k -u $USER_ID:$PASSWD https://api.play.cureatr.com/api/2014-08-01/thread/create -d subject="Elevated ICP" -d patient_name="' + patient_name + '" -d message="Patient has ICP>20mmHg as of ' + lowTimeEnd.strftime("%I:%M%p on %B %d, %Y") + '" -d recipients=steven.baldassano@uphs.upenn.edu',shell=True)#post to cureatr
                        alert_times[0] = lowTimeEnd
                        write_alert_times(alert_times)
                        with open('notification_log.txt','a') as log:
                                log.write('Low alert at ' +  lowTimeEnd.strftime("%I:%M%p on %B %d, %Y") + 'with meanICP of ' + str(meanICP) +'\n')
        print('Time elapsed: ' + str(time.time()-t))

if __name__ == "__main__":
        main(sys.argv[0],sys.argv[1])
