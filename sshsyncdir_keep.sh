#!/bin/bash

shopt -s dotglob
shopt -s nullglob

appdir_local=/home/dungnt/ShellScript/sshsyncapp

memtemp_local="$appdir_local"/.temp

#for COMPARE
copyfilesize="10MB"
truncsize=10000000


get_src_content_file_md5sum(){
	local param1=$1
	local cmd
	local filesizedest
	local cursizedest
	local mytemp="$memtemp_local"
	local kq
	
	rm "$mytemp""/output.beingcompare" > /dev/null 2>&1
	
	filesizedest=$(wc -c "$param1" | awk '{print $1}')
	cmd=$?
	
	if [ "$cmd" -eq 0 ] && [ "$filesizedest" ] && [ "$filesizedest" -gt 0 ] ; then
		cursizedest=$(($filesizedest / $truncsize))
		if [ "$cursizedest" -gt 0 ] ; then
			cursizedest=$(($cursizedest - 1))
			dd if="$param1" of="$mytemp""/output.beingcompare" bs="$copyfilesize" count=2 skip="$cursizedest" > /dev/null 2>&1
		else
			dd if="$param1" of="$mytemp""/output.beingcompare" bs="$copyfilesize" count=1 skip="0" > /dev/null 2>&1
		fi
		
		kq=$(md5sum "$mytemp""/output.beingcompare" | awk '{ print $1 }')
		
	else
		kq="null"
	fi
	
	echo "$kq"
}

get_src_content_file_md5sum_w_offset(){
	local param=$1
	local offset=$2
	local jumpoffset
	local skipbs
	local cursizedest
	local s
	local startoffset
	local mytemp="$memtemp_local"
	local kq

	rm "$mytemp""/output.beingcompare2" > /dev/null 2>&1
	rm "$mytemp""/output.beingcompare3" > /dev/null 2>&1
	
	touch "$mytemp""/output.beingcompare3" > /dev/null 2>&1
	
	jumpoffset=0
	startoffset="$offset"
	
	while [ $offset -gt 0 ] ; do
		#echo "$offset"
		if [ "$offset" -gt 100000000 ] ; then
			s=100000000
			cursizedest=$(($offset / $s))
			skipbs=$(($jumpoffset / $s))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="100MB" count="$cursizedest" skip="$skipbs" > /dev/null 2>&1
			jumpoffset=$(($jumpoffset + ($cursizedest * $s)))
			offset=$(($startoffset - $jumpoffset))
		elif [ "$offset" -gt 10000000 ] ; then
			s=10000000
			cursizedest=$(($offset / $s))
			skipbs=$(($jumpoffset / $s))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="10MB" count="$cursizedest" skip="$skipbs" > /dev/null 2>&1
			jumpoffset=$(($jumpoffset + ($cursizedest * $s)))
			offset=$(($startoffset - $jumpoffset))
		elif [ "$offset" -gt 1000000 ] ; then
			s=1000000
			cursizedest=$(($offset / $s))
			skipbs=$(($jumpoffset / $s))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="1MB" count="$cursizedest" skip="$skipbs" > /dev/null 2>&1
			jumpoffset=$(($jumpoffset + ($cursizedest * $s)))
			offset=$(($startoffset - $jumpoffset))
		elif [ "$offset" -gt 100000 ] ; then
			s=100000
			cursizedest=$(($offset / $s))
			skipbs=$(($jumpoffset / $s))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="100kB" count="$cursizedest" skip="$skipbs" > /dev/null 2>&1
			jumpoffset=$(($jumpoffset + ($cursizedest * $s)))
			offset=$(($startoffset - $jumpoffset))
		elif [ "$offset" -gt 10000 ] ; then
			s=10000
			cursizedest=$(($offset / $s))
			skipbs=$(($jumpoffset / $s))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="10kB" count="$cursizedest" skip="$skipbs" > /dev/null 2>&1
			jumpoffset=$(($jumpoffset + ($cursizedest * $s)))
			offset=$(($startoffset - $jumpoffset))
		elif [ "$offset" -gt 1000 ] ; then
			s=1000
			cursizedest=$(($offset / $s))
			skipbs=$(($jumpoffset / $s))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="1kB" count="$cursizedest" skip="$skipbs" > /dev/null 2>&1
			jumpoffset=$(($jumpoffset + ($cursizedest * $s)))
			offset=$(($startoffset - $jumpoffset))
		else
			s=1
			cursizedest=$(($offset / $s))
			skipbs=$(($jumpoffset / $s))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="1c" count="$cursizedest" skip="$skipbs" > /dev/null 2>&1
			jumpoffset=$(($jumpoffset + ($cursizedest * $s)))
			offset=$(($startoffset - $jumpoffset))
		fi
		
		cat "$mytemp""/output.beingcompare2" >> "$mytemp""/output.beingcompare3"

	done
	
	filesize=$(wc -c "$mytemp""/output.beingcompare3" | awk '{print $1}')
	#echo "filesize:""$filesize"
	kq=$(get_src_content_file_md5sum "$mytemp""/output.beingcompare3")

	echo "$kq"
}
