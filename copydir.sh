#!/bin/bash

#danh cho copy dir

shopt -s dotglob
shopt -s nullglob
 
dir_ori=/home/dungnt/ShellScript/dirtest1
dir_dest=/home/dungnt/ShellScript/dirtest2
mem_temp=/home/dungnt/ShellScript/temp

copyfilesize="1MB"
truncsize=1000000
countsize=0
skipsize=0

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
	if [ $cmd == 1 ] ; then
		findresult=$(find "$mem_temp" -type f -name "$logtimefile")
		cmd=$?
		
		#echo $?
		#printf 'findresult:%s\n' "$findresult"
		
		#neu tim thay file
		if [ $cmd == 0 ] && [ $findresult ] ; then
			#printf 'here:%s' "$findresult"
			while IFS= read -r line
			do
			  value="$line"
			done < "$mem_temp"/"$logtimefile"
			
			curtime=$(($(date +%s%N)/1000000))
			#printf 'curtime:%s\n' "$curtime"

			delaytime=$(( ( $curtime - $value ) / 60000 ))
			#printf 'delaytime:%s\n' "$delaytime"" minutes"
			if [ $delaytime -gt 5 ] ; then
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

copy_file() {
	local param1=$1
	local param2=$2
	local param3=$3
	local filesize
	local cursize
	local cmd
	local kq
	
	kq=0
	
	printf 'copy:%s to %s\n' "$param1" "$param2"
	filesize=$(wc -c "$param1" | awk '{print $1}')
	cmd=$?
	
	if [ "$cmd" -eq 0 ] && [ "$filesize" ] && [ "$filesize" -gt 0 ] ; then
	
		filesize=$(($filesize / $truncsize))
		printf 'filesize:%s\n' "$filesize"
		cursize=0
		
		while [ "$cursize" -lt "$filesize" ]
		do
			rm "$mem_temp""/""output.beingcopy"
			
			#printf 'dd:%s to %s\n' "$param1" "$mem_temp""/""$param3"
			dd if="$param1" of="$mem_temp""/""output.beingcopy" bs="$copyfilesize" count=1 skip="$cursize"
			if [ "$cursize" -eq 0 ]
				then
					cp "$mem_temp""/""output.beingcopy" "$param2""$param3"
				else
					cat "$mem_temp""/""output.beingcopy" >> "$param2""$param3"
			fi

			cursize=$(($cursize + 1))
			echo $cursize
			#verify logged after each loop
			verify_logged
			cmd=$?
			
			#if verifyresult: having active user/connection -> break
			if [ "$cmd" -lt 10 ] ; then
				kq=1
				break
			fi
		done
		
		if [ "$kq" -eq 0 ] ; then
			#lam lan cuoi
			rm "$mem_temp""/""output.beingcopy"
			
			skipsize=$cursize
			
			dd if="$param1" of="$mem_temp""/""output.beingcopy" bs="$copyfilesize" skip="$skipsize"
			cat "$mem_temp""/""output.beingcopy" >> "$param2""$param3"
		fi
	fi
	
	return "$kq"
}


copy_dir () {
	local param1=$1
	local param2=$2
	local pathname
	local curbasename
	local curfilename
	local cmd
	
	printf 'goi de quy voi:%s %s\n' "$param1" "$param2"
    for pathname in "$param1"/*; do
        if [ -d "$pathname" ]; then
			#printf 'dir:%s\n' "$pathname"
			#lay ten thu muc
			curbasename=$(basename "$pathname")
			printf 'curbasename:%s\n' "$curbasename"
			echo "mkdir:""$param2""/""$curbasename""/"
			mkdir "$param2""/""$curbasename"
            copy_dir "$pathname" "$param2""/""$curbasename"
        else
			curfilename=$(basename "$pathname")
            copy_file "$pathname" "$param2""/" "$curfilename"
			cmd=$?
			if [ "$cmd" -eq 1 ] ; then
				echo 'break in copy process'
				break
			fi
        fi
    done
}

copy_dir "$dir_ori" "$dir_dest"


