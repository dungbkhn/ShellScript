#!/bin/bash

shopt -s dotglob
shopt -s nullglob
 
file_ori="/home/dungnt/ShellScript/dirtest1/a   b.txt"
file_dest="/home/dungnt/ShellScript/dirtest2/a   b.txt"
mem_temp=/home/dungnt/ShellScript/temp

copyfilesize="1KB"
truncsize=1000
countsize=0
skipsize=0



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

check_same_file "$file_ori" "$file_dest"
compareresult=$?
#printf 'check same file:%s\n' "$compareresult"
if [ "$compareresult" == 1 ]; then
	printf 'two files are the same\n'
elif [ "$compareresult" == 2 ]; then
	printf 'dest file needed to be appended\n'
else
	printf 'two files are diff or other reasons\n'
fi
