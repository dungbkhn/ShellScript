#!/bin/bash
 
shopt -s dotglob
shopt -s nullglob

################################################
dirgenC=/home/backup/sha256
filegenC=gen256hash.c
shaC=sha256.c
fileoutgen=gen256hash.out
logfile=logcheckgen256hash.txt
sleeptime="3600"

sleep 60
################################################


if [ ! -f "$dirgenC"/"$fileoutgen" ] ; then
	gcc "$dirgenC"/"$filegenC" "$dirgenC"/"$shaC" -D_LARGEFILE_SOURCE=1 -D_FILE_OFFSET_BITS=64 -o "$dirgenC"/"$fileoutgen"
fi



#thuc thi file binary
cd "$dirgenC"
#chay file voi child process o phia background
./"$fileoutgen" &

findpidof256hash=0

rm "$dirgenC"/"$logfile" 
touch "$dirgenC"/"$logfile"

while true
do
	findpidof256hash=$(pidof gen256hash.out)
	
	if [ "$?" -eq 1 ] && [ ! "$findpidof256hash" ] ; then
		echo 'process ko thay' >> "$dirgenC"/"$logfile"
		#thuc thi file binary
		cd "$dirgenC"
		#chay file voi child process o phia background
		./"$fileoutgen" &
	fi

	sleep "$sleeptime"
done
