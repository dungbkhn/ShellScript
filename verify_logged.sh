#!/bin/bash

shopt -s dotglob
shopt -s nullglob
 
dir_ori=/home/dungnt/ShellScript/dirtest1
dir_dest=/home/dungnt/ShellScript/dirtest2
mem_temp=/home/dungnt/ShellScript/temp
logtimefile="userlogged.checkfile"


verify_logged() {
	#mac dinh la ko thay active user 
	local kq
	local findresult
	local cmd
	local line
	local value
	local curtime
	local delaytime
	
	kq=0
	
	netstat -atn | grep ':22' | grep 'ESTABLISHED'
	cmd=$?
	
	#neu ko tim thay co active connection 
	if [ "$cmd" -eq 1 ] ; then
		findresult=$(find "$mem_temp" -type f -name "$logtimefile")
		cmd=$?
		
		#echo $?
		#printf 'findresult:%s\n' "$findresult"
		
		#neu tim thay file
		if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
			#printf 'here:%s' "$findresult"
			while IFS= read -r line
			do
			  value="$line"
			done < "$mem_temp"/"$logtimefile"
			
			curtime=$(($(date +%s%N)/1000000))
			#printf 'curtime:%s\n' "$curtime"

			delaytime=$(( ( $curtime - $value ) / 60000 ))
			#printf 'delaytime:%s\n' "$delaytime"" minutes"
			if [ "$delaytime" -gt 5 ] ; then
				#ko thay active user
				kq=255
				rm "$mem_temp"/"$logtimefile"
			else
				#tim thay co active user
				kq=1
			fi
		else
			#ko thay active user's logfile
			kq=254
		fi
	else
		#tim thay co active connection 
		kq=0
	fi

	return "$kq"
}



verify_logged
kq=$?
printf 'kq:%s\n' "$kq"
if [ "$kq" -gt 10 ] ; then
	echo 'hello'
fi
