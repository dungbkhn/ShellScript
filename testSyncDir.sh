#!/bin/bash

shopt -s dotglob
shopt -s nullglob
 
dir_ori=/var/res/file
dir_dest=/home/backup/sharedFolder
mem_temp=/home/dungnt/Temp
dir_dest_par=/home/backup
dir_dest_c=/home/backup/backupMainClient

sleeptime=180
#for PRINTING
prt=0
copyfilesize="100MB"
truncsize=100000000
countsize=0
skipsize=0

#checksamefileresult=""

#for FIND SAME DIR
founddirname=""

#----------------------------------------TOOLS-------------------------------------

myecho(){
	local param=$1
	
	if [ $prt -eq 1 ]; then
			echo "$param"
	fi
}

myprintf(){
	local param1=$1
	local param2=$2
	
	if [ $prt -eq 1 ]; then
			printf "$param1"": %s\n" "$param2"
	fi
}


#------------------------------ VERIFY ACTIVE USER --------------------------------
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

#------------------------------ FIND SAME FILE --------------------------------

check_content_file(){
	#echo 'check_content_file'
	local param1=$1
	local param2=$2
	
	cmp "$param1" "$param2"
    
    #exit code
	#2,>2: file not found or other problems
	#1: diff
	#0: ok, same content

	return "$?"
}


check_same_file () {
	local param1=$1
	local param2=$2
	local kq
	local filesizedest
	local cursizedest
	local cursize
	local cmd
	
	cmp "$param1" "$param2"
	cmd=$?
	
	if [ "$cmd" -eq 0 ] ; then
		kq=1
	elif [ "$cmd" -eq 1 ] ; then
	
		rm "$mem_temp""/""output.beingcompare1"
		rm "$mem_temp""/""output.beingcompare2"
		
		filesizedest=$(wc -c "$param2" | awk '{print $1}')
		cmd=$?
		
		if [ "$cmd" -eq 0 ] && [ "$filesizedest" ] && [ "$filesizedest" -gt 0 ] ; then
			
			cursizedest=$(($filesizedest / $truncsize))
			#echo "$cursizedest"
			#cursizedest phai lon hon hoac bang 2
			if [ "$cursizedest" -gt 1 ] ; then
				
				cursizedest=$(($cursizedest - 2))
				#echo $cursizedest
				dd if="$param2" of="$mem_temp""/""output.beingcompare1" bs="$copyfilesize" count=1 skip="$cursizedest"

				cursize=$cursizedest
				dd if="$param1" of="$mem_temp""/""output.beingcompare2" bs="$copyfilesize" count=1 skip="$cursize"

				cmp "$mem_temp""/""output.beingcompare1" "$mem_temp""/""output.beingcompare2"
				cmd=$?
				
				if [[ "$cmd" -ne 0 ]]; then
					kq=255
				else 
					kq=2
				fi
			else
				#if cursizedest < 2
				kq=0
			fi
		else
			#if file not found or filesize fail
			kq=0
		fi
	else
		kq=255
	fi
	
	return "$kq"
}


find_same_file () {
	local param1=$1
	local param2=$2
	local srccurfilename
	local curfilename
	local findresult
	local pathname
	local curdirname
	local cmd
	local kq
	
	curfilename=$(basename "$param1")
	findresult=$(find "$param2" -type f -name "$curfilename")
	cmd=$?
	
	#neu tim thay
	if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
		myecho "tim thay file"
		
		check_same_file "$param1" "$param2""$curfilename"
		cmd=$?

		if [ "$cmd" -eq 1 ]; then
			myprintf "two files are the same" ""
			kq=0
		elif [ "$cmd" -eq 2 ]; then
			myprintf "dest file needed to be appended" ""
			kq=1
		else
			myprintf "two files are diff or other reason" ""
			rm "$param2""$curfilename"
			kq=255
		fi
	else
		kq=255
		#echo 'ko tim thay file'
		srccurfilename=$curfilename
		for pathname in "$param2"/*; do
			if [ ! -d "$pathname" ]; then
				curfilename=$(basename "$pathname")
				#echo $curfilename
				check_content_file "$param1" "$param2""$curfilename"
				cmd=$?
				
				if [ "$cmd" -eq 0 ]; then
					#echo $curfilename
					#mapping nguoc lai
					curdirname=$(dirname "$param1")
					findresult=$(find "$curdirname" -type f -name "$curfilename")
					cmd=$?
					
					#neu tim thay
					if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
						printf 'nhung file nay da mapping voi file khac o thu muc nguon roi\n'
					else
						printf 'da tim thay file khac ten nhung cung noi dung\n'
						#checksamefileresult=$curfilename
						mv "$param2""$curfilename" "$param2""$srccurfilename"
						kq=3
						break
					fi
				fi
			fi
		done
	fi
	
	return "$kq"
}

#------------------------------ APPEND FILE --------------------------------

append_file() {
	local param1=$1
	local param2=$2
	local param3=$3
	local filesizedest
	local cursizedest
	local cursize
	local filesize
	local cmd
	local kq
	
	kq=0
	printf 'append:%s to %s\n' "$param1" "$param2""$param3"
	
	filesizedest=$(wc -c "$param2""$param3" | awk '{print $1}')
	cmd=$?
	
	if [ "$cmd" -eq 0 ] && [ "$filesizedest" ] && [ "$filesizedest" -gt 0 ] ; then
		cursizedest=$(($filesizedest / $truncsize))
		#cursizedest phai lon hon hoac bang 2, xem check_same_file
		cursizedest=$(($cursizedest - 2))
		myecho "$cursizedest"
		
		cursize=$cursizedest
		
		printf 'begin append'
		filesize=$(wc -c "$param1" | awk '{print $1}')
		cmd=$?
		
		if [ "$cmd" -eq 0 ] && [ "$filesize" ] && [ "$filesize" -gt 0 ] ; then
		
			filesize=$(($filesize / $truncsize))
			printf 'filesize:%s\n' "$filesize"

			while [ "$cursize" -lt "$filesize" ]
			do
				rm "$mem_temp""/""output.beingcopy"
				
				#printf 'dd:%s to %s\n' "$param1" "$mem_temp""/""$param3"
				dd if="$param1" of="$mem_temp""/""output.beingcopy" bs="$copyfilesize" count=1 skip="$cursize"
				dd if="$mem_temp""/""output.beingcopy" of="$param2""$param3" bs="$copyfilesize" count=1 seek="$cursize"

				cursize=$(($cursize + 1))
				myecho "$cursize"
				
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
				dd if="$param1" of="$mem_temp""/""output.beingcopy" bs="$copyfilesize" skip="$cursize"
				dd if="$mem_temp""/""output.beingcopy" of="$param2""$param3" bs="$copyfilesize" seek="$cursize"
			fi
		fi
	fi
	
	return "$kq"
}

#------------------------------ COPY FILE --------------------------------

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
			myecho "$cursize"
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

#------------------------------ FIND SAME DIR --------------------------

check_same_dir () {
	local param1=$1
	local param2=$2
	local pathname1
	local pathname2
	local curfilename1
	local curfilename2
	local countsameelement
	
	countsameelement=0
	
	for pathname1 in "$param1"/*; do
		curfilename1=$(basename "$pathname1")
		for pathname2 in "$param2"/*; do
			if [ -d "$pathname1" ]; then
				if [ -d "$pathname2" ]; then
					curfilename2=$(basename "$pathname2")
					if [ "$curfilename1" == "$curfilename2" ] ; then
						countsameelement=$(($countsameelement + 1))
					fi
				fi
			else
				if [ ! -d "$pathname2" ]; then
					curfilename2=$(basename "$pathname2")
					if [ "$curfilename1" == "$curfilename2" ] ; then
						countsameelement=$(($countsameelement + 1))
					fi
				fi
			fi
		done
	done
	

	
	return "$countsameelement"
}

find_same_dir () {
	local param1=$1
	local param2=$2
	local param3=$3
	local curdirname
	local pathname
	local countsameelement
	local findresult
	local max
	local cmd
	local kq
	
	#echo "$param2"
	#echo "$param3"
	
	findresult=$(find "$param2" -type d -name "$param3")
	cmd=$?
	
	#neu tim thay thu muc o dia chi dich trung ten
	if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
		kq=1
	else
		#neu ko tim thay
		max=1
		for pathname in "$param2"/*; do
			if [ -d "$pathname" ]; then
				#mapping nguoc lai
				curdirname=$(basename "$pathname")
				findresult=$(find "$param1" -type d -name "$curdirname")
				cmd=$?
				
				if [ ! "$findresult" ] ; then
					#neu ko tim thay khi mapping thi so sanh noi dung 2 thu muc
					check_same_dir "$param1""/""$param3" "$pathname"
					cmd=$?
					if [ "$cmd" -gt "$max" ]; then
						max=$cmd
						founddirname=$pathname
					fi
				fi
			fi
		done
		
		printf 'max:%s\n' "$max"
		
		if [ "$max" -gt 1 ]; then
			kq=2
		else
			kq=0
		fi
		
	fi
	
	#0:ko tim thay
	#1:tim thay trung ten
	#2:tim thay khac ten nhung noi dung chua nhieu ptu giong nhau
	
	return "$kq"
}

#------------------------------ COPY DIR --------------------------------

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
			#echo "mkdir:""$param2""/""$curbasename""/"
			mkdir "$param2""/""$curbasename"
            copy_dir "$pathname" "$param2""/""$curbasename"
        else
			curfilename=$(basename "$pathname")
            copy_file "$pathname" "$param2""/" "$curfilename"
			cmd=$?
			if [ "$cmd" -eq 1 ] ; then
				#echo 'break in copy process'
				break
			fi
        fi
    done
}

#------------------------------ REMOVE REDUNDANT FILES ------------------

remove_redundant_files(){
	local param1=$1
	local param2=$2
	local pathname
	local curbasename
	local curfilename
	local findresult
	local cmd
	
	
	for pathname in "$param2"/*; do
		
		if [ -d "$pathname" ]; then
			#lay ten thu muc
			curbasename=$(basename "$pathname")
			findresult=$(find "$param1" -type d -name "$curbasename")
			cmd=$?
			#neu tim thay
			if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
				myecho "thay thu muc"
			else
				rm -r "$param2"/"$curbasename"/
			fi
		else
			#lay ten file
			curfilename=$(basename "$pathname")
			findresult=$(find "$param1" -type f -name "$curfilename")
			cmd=$?
			#neu tim thay
			if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
				myecho "thay file"
			else
				rm "$param2"/"$curfilename"
			fi
		fi
	done
}

#------------------------------ SYNC DIR --------------------------------

sync_dir () {
	local param1=$1
	local param2=$2
	local curbasename
	local curfilename
	local pathname
	local cmd
	
	#printf 'goi ham sync_dir voi:%s %s\n' "$param1" "$param2"
    for pathname in "$param1"/*; do
        if [ -d "$pathname" ]; then
			#lay ten thu muc
			curbasename=$(basename "$pathname")
			myprintf "lay ten thu muc curbasename" "$curbasename"
			find_same_dir "$param1" "$param2" "$curbasename"
			cmd=$?
			if [ "$cmd" -eq 0 ] ; then
				#echo 'ko tim thay'
				myecho "mkdir:""$param2""/""$curbasename"
				mkdir "$param2""/""$curbasename"
				copy_dir "$pathname" "$param2""/""$curbasename"
			elif [ "$cmd" -eq 2 ] ; then
				#echo 'tim thay khac ten trung noi dung'
				myecho "mv:""$founddirname"" ""$param2""/""$curbasename"
				mv "$founddirname" "$param2""/""$curbasename"
				sync_dir "$pathname" "$param2""/""$curbasename"
			else
				myecho "tim thay trung ten"
				sync_dir "$pathname" "$param2""/""$curbasename"
			fi
			
        else
			curfilename=$(basename "$pathname")
            
            find_same_file "$pathname" "$param2""/"
			cmd=$?
			
			if [ "$cmd" -eq 255 ] ; then
				copy_file "$pathname" "$param2""/" "$curfilename"
				cmd=$?
				if [ "$cmd" -eq 1 ] ; then
					myecho "break in copy process"
					break
				fi
			elif [ "$cmd" -eq 1 ] ; then
				#append----------------------------------------------------"
				append_file "$pathname" "$param2""/" "$curfilename"
				cmd=$?
				if [ "$cmd" -eq 1 ] ; then
					myecho "break in append process"
					break
				fi
			fi
			
        fi
    done
    
    remove_redundant_files "$param1" "$param2"
}


#------------------------------ MAIN --------------------------------

main(){
	local cmd
	local pathname

	sleep 9m
	
	rm "$mem_temp"/*
	
	if [ ! -d "$dir_dest" ] ; then
		mkdir "$dir_dest"
	fi

	if [ ! -d "$dir_dest_c" ] ; then
                mkdir "$dir_dest_c"
        fi

	for pathname in "$dir_dest_par"/* ; do
        	if [ -d "$pathname" ] ; then
                        if [ "$pathname" != "$dir_dest" ] && [ "$pathname" != "$dir_dest_c" ] ; then
                                rm -r "$pathname"
                        fi
                else
                        rm "$pathname"
        	fi
	done

	while true; do
		
		verify_logged
		cmd=$?
		
		#if verifyresult: no active user -> sync_dir
		if [ "$cmd" -gt 10 ] ; then
			myecho "begin sync dir"
			sync_dir "$dir_ori" "$dir_dest"
			echo "go to sleep 1"
			sleep "$sleeptime"m
		else
			echo "go to sleep 2"
			sleep "$sleeptime"m
		fi

	done
	
}

main


