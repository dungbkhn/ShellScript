#!/bin/bash

shopt -s dotglob
shopt -s nullglob
 
file_ori="/home/dungnt/ShellScript/dirtest1/a   b.txt"
dir_dest=/home/dungnt/ShellScript/dirtest2/
mem_temp=/home/dungnt/ShellScript/temp

copyfilesize="1KB"
truncsize=1000
countsize=0
skipsize=0

checksamefileresult=""

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
		echo 'tim thay file'
		#echo "$param1"
		#echo "$param2""$curfilename"
		check_same_file "$param1" "$param2""$curfilename"
		cmd=$?
		#echo "$cmd"
		if [ "$cmd" -eq 1 ]; then
			printf 'two files are the same\n'
			kq=0
		elif [ "$cmd" -eq 2 ]; then
			printf 'dest file needed to be appended\n'
			kq=1
		else
			printf 'two files are diff or other reason\n'
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
						checksamefileresult=$curfilename
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

find_same_file "$file_ori" "$dir_dest"
echo "$?"
echo "$checksamefileresult"
