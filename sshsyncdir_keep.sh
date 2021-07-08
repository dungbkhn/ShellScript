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

sync_file_in_dir_old(){
	local param1=$1
	local param2=$2
	local mytemp="$memtemp_local"
	local outputfile1_inremote="outputfile1_inremote.txt"
	local cmd
	local findresult
	local count
	local beforeslash
	local afterslash_1
	local afterslash_2
	local afterslash_3
	local afterslash_4
	local afterslash_5
	local afterslash_6
	local filesize
	local md5tailhash
	local mtime
	local mtime_temp
	
	# declare array
	declare -a name
	declare -a size
	declare -a tailmd5sum
	declare -a mtime_arr
	
	if [ -f "$mytemp"/"$outputfile1_inremote" ] ; then
		count=0
		while IFS=/ read beforeslash afterslash_1 afterslash_2 afterslash_3 afterslash_4 afterslash_5 afterslash_6
		do
			if [ "$afterslash_1" != "" ] ; then
				if [ "$afterslash_2" -eq 0 ] ; then
					name[$count]="$afterslash_1"
					size[$count]="$afterslash_4"
					tailmd5sum[$count]="$afterslash_5"
					mtime_arr[$count]="$afterslash_6"
					echo "${name[$count]}""-----""${size[$count]}""-----""${tailmd5sum[$count]}""-----""${mtime[$count]}"
					count=$(($count + 1))
				fi
			else
				echo "--------------------file received valid---------------------"
			fi
		done < "$mytemp"/"$outputfile1_inremote"
		
		
		count=0
		for i in "${!name[@]}"
		do
			findresult=$(find "$param1" -maxdepth 1 -type f -name "${name[$i]}")
			#echo "findresultlandau-----------:""$findresult"
			cmd=$?
			#neu tim thay
			if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
				filesize=$(wc -c "$param1""/""${name[$i]}" | awk '{print $1}')
				mtime_temp=$(stat "$param1""/""${name[$i]}" --printf='%y\n')
				mtime=$(date +'%s' -d "$mtime_temp")
				#echo "${name[$i]}""-----""$filesize""-----""$md5tailhash""-----""$mtime"
				#echo "${name[$i]}""-----""${size[$i]}""-----""${tailmd5sum[$i]}""-----""${mtime_arr[$i]}"
				if [ "$filesize" -eq "${size[$i]}" ] ; then
					md5tailhash=$(get_src_content_file_md5sum "$findresult")
					#echo "$md5tailhash"
					if [ "$mtime" -eq "${mtime_arr[$i]}" ] ; then
						if [ "$md5tailhash" == "${tailmd5sum[$i]}" ] ; then
							echo '11--------'"${name[$i]}"' ten, size, mtime, tailhash bang nhau'
						else
							echo '12--------'"${name[$i]}"' ten, size, mtime bang nhau nhung tailhash khac nhau'
						fi
					elif [ "$mtime" -gt "${mtime_arr[$i]}" ] ; then
						if [ "$md5tailhash" == "${tailmd5sum[$i]}" ] ; then
							echo '21--------'"${name[$i]}"' ten, size, tailhash bang nhau nhung mtime remote nho hon'
						else
							echo '22--------'"${name[$i]}"' ten, size bang nhau nhung tailhash khac nhau, mtime remote nho hon'
						fi
					else
						if [ "$md5tailhash" == "${tailmd5sum[$i]}" ] ; then
							echo '31--------'"${name[$i]}"' ten, size, tailhash bang nhau nhung mtime remote lon hon'
						else
							echo '32--------'"${name[$i]}"' ten, size bang nhau nhung tailhash khac nhau, mtime remote lon hon'
						fi
					fi
				elif [ "$filesize" -gt "${size[$i]}" ] ; then
					echo '001--------'"${name[$i]}"':  cung ten nhung kich thuoc phia remote nho hon'
					md5tailhash=$(get_src_content_file_md5sum_w_offset "$findresult" "${size[$i]}")
					#echo "find:""$findresult""---------""${size[$i]}""---------"
					#echo "md5tailhash:""$md5tailhash"
					#echo "${tailmd5sum[$i]}"
					
					if [ "$mtime" -eq "${mtime_arr[$i]}" ] ; then
						if [ "$md5tailhash" == "${tailmd5sum[$i]}" ] ; then
							echo '001-11--------'"${name[$i]}"' ten, mtime, tailhash bang nhau'
						else
							echo '001-12--------'"${name[$i]}"' ten, mtime bang nhau nhung tailhash khac nhau'
						fi
					elif [ "$mtime" -gt "${mtime_arr[$i]}" ] ; then
						if [ "$md5tailhash" == "${tailmd5sum[$i]}" ] ; then
							echo '001-21--------'"${name[$i]}"' ten, tailhash bang nhau nhung mtime remote nho hon'
						else
							echo '001-22--------'"${name[$i]}"' ten bang nhau nhung tailhash khac nhau, mtime remote nho hon'
						fi
					else
						if [ "$md5tailhash" == "${tailmd5sum[$i]}" ] ; then
							echo '001-31--------'"${name[$i]}"' ten, tailhash bang nhau nhung mtime remote lon hon'
						else
							echo '001-32--------'"${name[$i]}"' ten, nhung tailhash khac nhau, mtime remote lon hon'
						fi
					fi
				else
					echo '00000000000002--------'"${name[$i]}"':  cung ten nhung kich thuoc phia remote lon hon'
				fi
			#neu ko tim thay
			else
				printf 'error\n'
			fi
			
		done
	fi
}
