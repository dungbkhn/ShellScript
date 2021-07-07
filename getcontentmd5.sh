#!/bin/bash
 
shopt -s dotglob
shopt -s nullglob

memtemp_local=$(pwd)

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
	local cursizedest
	local mytemp="$memtemp_local"
	local count
	local kq

	rm "$mytemp""/output.beingcompare2" > /dev/null 2>&1

	count=0
	while [ $count -lt 5 ] ; do
		if [ "$offset" -gt 100000000 ] ; then
			cursizedest=$(($offset / 100000000))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="100MB" count="$cursizedest" skip=0 > /dev/null 2>&1
			offset=$(($offset - ($cursizedest * 100000000)))
		elif [ "$offset" -gt 10000000 ] ; then
			cursizedest=$(($offset / 10000000))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="10MB" count="$cursizedest" skip=0 > /dev/null 2>&1
			offset=$(($offset - ($cursizedest * 10000000)))
		elif [ "$offset" -gt 1000000 ] ; then
			cursizedest=$(($offset / 1000000))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="1MB" count="$cursizedest" skip=0 > /dev/null 2>&1
			offset=$(($offset - ($cursizedest * 1000000)))
		elif [ "$offset" -gt 100000 ] ; then
			cursizedest=$(($offset / 100000))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="100kB" count="$cursizedest" skip=0 > /dev/null 2>&1
			offset=$(($offset - ($cursizedest * 100000)))
		elif [ "$offset" -gt 10000 ] ; then
			cursizedest=$(($offset / 10000))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="10kB" count="$cursizedest" skip=0 > /dev/null 2>&1
			offset=$(($offset - ($cursizedest * 10000)))
		elif [ "$offset" -gt 1000 ] ; then
			cursizedest=$(($offset / 1000))
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="1kB" count="$cursizedest" skip=0 > /dev/null 2>&1
			offset=$(($offset - ($cursizedest * 1000)))
		else
			cursizedest="$offset"
			dd if="$param" of="$mytemp""/output.beingcompare2" bs="1c" count="$cursizedest" skip=0 > /dev/null 2>&1
			offset=0
		fi
		
		if [ "$count" -eq 0 ] ; then
			mv "$mytemp""/output.beingcompare2" "$mytemp""/output.beingcompare3"
		else
			cat "$mytemp""/output.beingcompare2" >> "$mytemp""/output.beingcompare3"
		fi
		
		count=$(($count + 1))
	done
	
	
	kq=$(get_src_content_file_md5sum "$mytemp""/output.beingcompare3")

	echo "$kq"
}
