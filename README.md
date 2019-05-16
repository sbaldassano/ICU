# ICU
Scripts for analysis of streaming multimodality ICU data for IRIS platform.
Current functionality includes two modules. The first module pulls data from Natus Nicolet EEG Monitors (EEG), and the second pulls data from Moberg CNS Monitors (intracranial monitoring).

Included are key pipeline scripts for accessing data from EEG or Moberg monitors, as well as algorithms for event detection. Note that most pipeline and data management code is monitor/institution specific, but can serve as general guideline for researchers instituting a similar system. 

1) EEG Monitoring
This pathway consists of the following files:  
-master.sh: bash script used to organize pipeline and determine if a given monitor is currently active  
-readNicolet.m: custom matlab script (more detail at https://github.com/ieeg-portal/Nicolet-Reader) used to process Natus Nicolet EEG files  
-getData.m: Extracts new data and patient metadata from processed Nicolet file
-lead integrity.m: Assesses data quality from EEG leads. Uses a custom algorithm (highlighted in code) to identify leads with poor signal. If such leads are detected, uses jsonPost to send a notification through Cureatr
-BStrend.m and BSdetect.m: Used to detect areas of suppressed EEG to trigger burst suppression trending. Includes custom algorithm to train centroids for burst and suppressed EEG on a per-patient basis. Sends Cureatr notifications with past 1 hour of BSR trend (until EEG is no longer suppressed).


2) Intrcranial Monitoring
-ICP and PbO2 data were pulled from Moberg CNS Monitors using a combination of Moberg proprietary code and custom scripts. This code is proprietary and cannot be made public under agreement with Moberg, Inc.
-ICP_cron.py: Used to keep track of algorithm progress and trigger analysis at specified time interval
-ICP_detect.py: Used to identify periods of elevated ICP and/or decreased PbO2 in accordance with user specifications. Triggers a Cureatr notification for detected events.


