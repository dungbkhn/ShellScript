#!/bin/bash

shopt -s dotglob
shopt -s nullglob
 
dir_src=/home/dungnt/ShellScript/dirtest1/t1
dir_dest=/home/dungnt/ShellScript/dirtest2/t2
mem_temp=/home/dungnt/ShellScript/temp

copyfilesize="1KB"
truncsize=1000
countsize=0
skipsize=0


check_same_dir () {
	local param1=$1
	local param2=$2
	local curfilename1
	local curfilename2
	local curdirname1
	local curdirname2
	local countsameelement
	local findresult
	local cmd
	local kq
	
	curfilename1=$(basename "$param1")
	curfilename2=$(basename "$param2")
	curdirname1=$(dirname "$param1")
	curdirname2=$(dirname "$param2")
	
	if [ "$curfilename1" == "$curfilename2" ] ; then
		kq=1
	else
		#hai thu muc co ten ko giong nhau
		echo 'kiem tra gan giong nhau'
		echo "$curdirname1"
		echo "$curfilename2"
		#mapping nguoc
		findresult=$(find "$curdirname1" -type d -name $curfilename2)
		cmd=$?
		
		#neu tim thay khi mapping nguoc
		if [ $cmd == 0 ] && [ $findresult ] ; then
			printf 'thu muc nay da mapping voi thu muc khac o dia chi nguon roi\n'
			kq=3
		else
		
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
			
			if [ "$countsameelement" -gt 1 ] ; then
				kq=2
			else
				kq=0
			fi
		fi
	fi
	
	#1: ten 2 thu muc giong het nhau
	#2: ten 2 thu muc khac nhau nhung chua 2 ptu ten giong nhau
	#3: ten 2 thu muc khac nhau, thu muc dich ton tai o dia chi nguon
	#0: ten 2 thu muc khac nhau, thu muc dich ko co o dia chi nguon, ko chua ptu giong ten nhau
	return "$kq"
}

check_same_dir "$dir_src" "$dir_dest"

echo $?
