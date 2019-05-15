#!/bin/bash
MONDIR="/home/sbaldassano/monitor3/"

if ping -c 1 monitor3 &> /dev/null
then
        /bin/umount $MONDIR 2>/dev/null
        echo ping success, try to mount
        {
                /sbin/mount.cifs //monitor3/Nicolet/NicOne/data/ $MONDIR -o credentials=/home/sbaldassano/cred 
        } || {
                  echo failed && exit 1 
        }
else
        exit 1
fi
echo mount success
cd $MONDIR;

NEWDIR=$(ls -d */ -t|head -n1)

PTH="$MONDIR$NEWDIR"
cd $PTH;

FILENAME=$(ls|grep .e$)
FULLPTH="$PTH$FILENAME"
echo Last modified is $FULLPTH
FILESIZE=$(stat -c%s $FILENAME)
echo file size is $FILESIZE

cd "/home/sbaldassano/monitor3_processing/";
echo about to run readNicolet
/home/sbaldassano/scripts/run_readNicolet.sh /usr/bin/v83 $FULLPTH $PWD > output.txt &&
echo done. about to run getdata &&
/home/sbaldassano/scripts/run_getdata.sh /usr/bin/v83 "output.txt" $PWD >> getdatalog.txt &&
echo done. about to run leadIntegrity &&
/home/sbaldassano/scripts/run_leadIntegrity.sh /usr/bin/v83 $PWD >> callLog.txt &&
echo done. about to run BSdetect &&
/home/sbaldassano/scripts/run_BSdetect.sh /usr/bin/v83 $PWD >> BSdetectLog.txt &&
echo done. about to run BStrend &&
/home/sbaldassano/scripts/run_BStrend.sh /usr/bin/v83 $PWD >> BStrendLog.txt
echo done.
