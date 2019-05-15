
import sys
import json
import urllib2
import base64


clientID = 'cdd6ac8b-560b-4ef4-971b-49302e519c9f'
MRN = str(sys.argv[1])
facility = 'HUP'
if int(sys.argv[2]) == 0:
        alertType = 'burst-suppression'
        if int(sys.argv[3]) == 1:
                detail = 'This patient has reached burst suppression'
        else:
                detail = 'This patient is no longer burst suppressed'
else:
        alertType = 'burst-trend'
        detail = 'The latest BSR is ' + str(sys.argv[3])
attachmentType = 'image/png'
imagePath = str(sys.argv[4])
with open(imagePath,'rb') as imageFile:
    attachmentData = base64.b64encode(imageFile.read())

data = {
        'clientId': clientID,
        'patientMrn': MRN,
        'patientMrnFacility':facility,
        'type': alertType,
        'detail': detail,
        'attachmentType': attachmentType,
        'attachmentData': attachmentData
        }

url = 'https://api.agent.uphs.upenn.edu/v1/events'

req = urllib2.Request(url)
req.add_header('Content-Type','application/json')
try:
    response = urllib2.urlopen(req, json.dumps(data))
    print 'it posted'

except urllib2.HTTPError, e:
    contents = e.read()
    print(contents)
