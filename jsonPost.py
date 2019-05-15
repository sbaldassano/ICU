#!/usr/bin/python

import sys
import json
import urllib2
import base64


clientID = 'cdd6ac8b-560b-4ef4-971b-49302e519c9f'
MRN = str(sys.argv[1])
facility = 'HUP'
alertType = 'disconnection'
detail = 'The signal from the following EEG leads is bad: ' + str(sys.argv[2])
attachmentType = 'image/png'
imagePath = str(sys.argv[3])
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