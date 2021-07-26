#!/bin/bash

temp_rm=/home/backup/md5hash

#512*1024*1024
level1=536870912
#1024*1024
level2=1048576
level3=2048
level4=1


if [ -f "$1" ] ; then
	filesize=$(wc -c "$1" | awk '{print $1}')
	
	if [ "$filesize" -ge "$level1" ] ; then
		ss=0
		n=$(( $filesize/$level1 ))
		rs=$(dd if="$1" bs="512M" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$rs"
		#echo "$hash"
		echo "$n""---""$ss"
		filesize=$(( $filesize - ($n*$level1) ))
		
		ss=$(( $n*$level1 ))
		n=$(( $filesize/$level2 ))
		rs=$(dd if="$1" bs="1M" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$hash""$rs"
		#echo "$hash"
		echo "$n""---""$ss"
		filesize=$(( $filesize - ($n*$level2) ))
		
		ss=$(( $ss + $n*$level2 ))
		n=$(( $filesize/$level3 ))
		rs=$(dd if="$1" bs="2048c" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$hash""$rs"
		#echo "$hash"
		echo "$n""---""$ss"
		filesize=$(( $filesize - ($n*$level3) ))
		
		ss=$(( $ss + $n*$level3 ))
		n=$(( $filesize/$level4 ))
		rs=$(dd if="$1" bs="1c" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$hash""$rs"
		echo "$hash"
		echo "$n""---""$ss"
		
	elif [ "$filesize" -ge "$level2" ] ; then
		ss=0
		n=$(( $filesize/$level2 ))
		rs=$(dd if="$1" bs="1M" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$rs"
		#echo "$hash"
		echo "$n""---""$ss"
		filesize=$(( $filesize - ($n*$level2) ))
		
		ss=$(( $ss + $n*$level2 ))
		n=$(( $filesize/$level3 ))
		rs=$(dd if="$1" bs="2048c" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$hash""$rs"
		#echo "$hash"
		echo "$n""---""$ss"
		filesize=$(( $filesize - ($n*$level3) ))
		
		ss=$(( $ss + $n*$level3 ))
		n=$(( $filesize/$level4 ))
		rs=$(dd if="$1" bs="1c" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$hash""$rs"
		echo "$hash"
		echo "$n""---""$ss"
		
	elif [ "$filesize" -ge "$level3" ] ; then
		ss=0
		n=$(( $filesize/$level3 ))
		rs=$(dd if="$1" bs="2048c" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$rs"
		#echo "$hash"
		echo "$n""---""$ss"
		filesize=$(( $filesize - ($n*$level3) ))
		
		ss=$(( $ss + $n*$level3 ))
		n=$(( $filesize/$level4 ))
		rs=$(dd if="$1" bs="1c" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$hash""$rs"
		echo "$hash"
		echo "$n""---""$ss"
	else
		ss=0
		n=$(( $filesize/$level4 ))
		rs=$(dd if="$1" bs="1c" count="$n" iflag=skip_bytes skip="$ss" | md5sum | awk '{print $1}')
		hash="$rs"
		echo "$hash"
		echo "$n""---""$ss"
	fi
	
	#rs=$("$temp_rm"/md5 "$1")
	#es=$("$temp_rm"/md5 "$1")
	#echo "$rs""$es"
	
	exit 0
else
	exit 1
fi

