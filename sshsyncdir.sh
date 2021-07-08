#!/bin/bash


shopt -s dotglob
shopt -s nullglob

dir_ori=/home/dungnt/ShellScript/dirtest1
dir_dest=/home/backup/storageBackup

appdir_local=/home/dungnt/ShellScript/sshsyncapp
appdir_remote=/home/backup

compare_listfile_inremote="comparelistfile_remote.sh"
dir_contains_uploadfiles="$appdir_local"/remotefiles
memtemp_local="$appdir_local"/.temp
memtemp_remote="$appdir_remote"/.temp
destipv6addr="backup@"
destipv6addr_scp="backup@[]"

filepubkey=/home/dungnt/.ssh/id_rsa_backup_58
logtimedir_remote=/home/dungnt/MyDisk_With_FTP/logtime
logtimefile=logtimefile.txt

find_list_same_files_recv="find_list_same_files_recv.txt"

sleeptime=5
#for PRINTING
prt=1
#for COMPARE
copyfilesize="10MB"
truncsize=10000000


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

#-------------------------------CHECK NETWORK-------------------------------------

check_network(){
	local state
	local cmd
	
	#trang thai mac dinh=0:ko co mang
	state=0
	
	ping -c 1 -W 1 -4 google.com
	cmd=$?
	
	if [ "$cmd" -eq 0 ] ; then
		#co mang
		state=1
	fi 
	
	if [ "$state" -eq 0 ] ; then
	
		ping -c 1 -W 1 -4 vnexpress.net
		cmd=$?

		if [ "$cmd" -eq 0 ] ; then
			#co mang
			state=1
		fi 
		
	fi

	#1: co mang
	#2: ko co mang
	return "$state"
}

#------------------------------ VERIFY ACTIVE USER --------------------------------
verify_logged() {
	#mac dinh la ko thay active user 
	local kq
	local result
	local cmd
	local mycommand
	local line
	local value
	local curtime
	local delaytime
	
	kq=0
	
	if [ -f "$filepubkey" ] ; then
	
		result=$(ssh -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "find ${logtimedir_remote} -maxdepth 1 -type f -name ${logtimefile}")
		cmd=$?
		echo "$result"
		if [ "$cmd" -eq 0 ] && [ "$result" ] ; then
				#echo 'tim thay' $logtimefile
				
				result=$(ssh -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "tail ${logtimedir_remote}/${logtimefile}")
				cmd=$?
				echo "$result"
				if [ "$cmd" -eq 0 ] && [ "$result" ] ; then
					curtime=$(($(date +%s%N)/1000000))
					#printf 'curtime:%s\n' "$curtime"
					value=$(echo "${result##*$'\n'}")
					printf 'value:%s\n' "$value"
					delaytime=$(( ( $curtime - $value ) / 60000 ))
					printf 'delaytime:%s\n' "$delaytime"" minutes"
					if [ "$delaytime" -gt 6 ] ; then
						#ko thay active web user
						kq=1
					else
						#tim thay co active web user
						kq=255
					fi
				fi
		fi
	fi

	#0: run function fail
	#1: no active web user found
	#255: active web user found
	return "$kq"
}

#------------------------------ FIND SAME FILE --------------------------------

find_list_same_files () {
	local param1=$1
	local param2=$2
	local count=0
	local mytemp="$memtemp_local"
	local workingdir=$(pwd)
	local cmd
	local cmd1
	local cmd2
	local result
	local mycommand
	local pathname
	local filesize
	local md5hash
	local mtime
	local mtime_temp
	local listfiles="listfiles.txt"
	local outputfile_inremote="outputfile_inremote.txt"
	
	
	rm "$mytemp"/*

	cd "$param1"/
	
	touch "$mytemp"/"$listfiles"
	
	for pathname in ./* ;do
		if [ -d "$pathname" ] ; then 
			printf "%s/%s/0/0/0\n" "$pathname" "d" >> "$mytemp"/"$listfiles"
		else
			filesize=$(wc -c "$pathname" | awk '{print $1}')
			md5hash=$(head -c 1024 "$pathname" | md5sum | awk '{ print $1 }')
			#md5tailhash=$(get_src_content_file_md5sum "$pathname")
			mtime_temp=$(stat "$pathname" --printf='%y\n')
			mtime=$(date +'%s' -d "$mtime_temp")
			#printf "%s/%s/%s/%s/%s/%s\n" "$pathname" "f" "$filesize" "$md5hash" "$md5tailhash" "$mtime" >> "$mytemp"/"$listfiles"
			printf "%s/%s/%s/%s/%s\n" "$pathname" "f" "$filesize" "$md5hash" "$mtime" >> "$mytemp"/"$listfiles"
		fi
	done

	cd "$workingdir"/
	

	
	result=$(scp -i "$filepubkey" -p "$mytemp"/"$listfiles" "$destipv6addr_scp":"$memtemp_remote"/)
	#echo "$mycommand"
	#result=$(eval $mycommand)
	cmd1=$?
	myprintf "scp 1 listfile" "$cmd1"
	
	
		
	result=$(scp -i "$filepubkey" -p "$dir_contains_uploadfiles"/"$compare_listfile_inremote" "$destipv6addr_scp":"$memtemp_remote"/)
	#echo "$mycommand"
	#result=$(eval $mycommand)
	cmd2=$?
	myprintf "scp 2 listfile" "$cmd2"
	
	
	
	if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] ; then

		result=$(ssh -i "$filepubkey" "$destipv6addr" "rm ${memtemp_remote}/${outputfile_inremote}")
		cmd=$?
		
		myprintf "ssh remove outputfile" "$cmd"
		
		result=$(ssh -i "$filepubkey" "$destipv6addr" "bash ${memtemp_remote}/comparelistfile_remote.sh /${listfiles} ${param2} ${outputfile_inremote}")
		cmd=$?
		
		myprintf "ssh gen outputfile" "$cmd"

		rm "$mytemp"/"$listfiles"
		
		result=$(scp -i "$filepubkey" -p "$destipv6addr_scp":"$memtemp_remote"/"$outputfile_inremote" "$mytemp"/)
		#echo "$mycommand"
		#result=$(eval $mycommand)
		cmd=$?
		myprintf "scp getback listfile" "$cmd"

	fi
	
	
}

#------------------------------ COPY FILE --------------------------------

sync_file_in_dir(){
	local param1=$1
	local param2=$2
	local mytemp="$memtemp_local"
	local outputfile_inremote="outputfile_inremote.txt"
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
	
	# declare array
	declare -a name
	declare -a size
	declare -a md5hash
	declare -a mtime
	
	if [ -f "$mytemp"/"$outputfile_inremote" ] ; then
		count=0
		while IFS=/ read beforeslash afterslash_1 afterslash_2 afterslash_3 afterslash_4 afterslash_5 afterslash_6
		do
			if [ "$afterslash_1" != "" ] ; then
				if [ "$afterslash_2" -eq 0 ] ; then
					name[$count]="$afterslash_1"
					size[$count]="$afterslash_4"
					md5hash[$count]="$afterslash_5"
					mtime[$count]="$afterslash_6"
					echo "${name[$count]}""-----""${size[$count]}""-----""${md5hash[$count]}""-----""${mtime[$count]}"
					count=$(($count + 1))
				fi
			else
				echo "--------------------file received valid---------------------"
			fi
		done < "$mytemp"/"$outputfile_inremote"
		
		
		count=0
		for i in "${!name[@]}"
		do
			findresult=$(find "$param1" -maxdepth 1 -type f -name "${name[$i]}")
			
			cmd=$?
			#neu tim thay
			if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
				echo "nhung file giong ten nhung khac attribute:""$findresult"
			#neu ko tim thay
			else
				printf 'error\n'
			fi
			
		done
	fi
}
	

copy_file_to_remote(){
	local param1=$1
	local param2=$2
	local mycommand
	local result
	local cmd
	local sshstring
	sshstring="ssh -i ""$filepubkey"
	
	if [ -f "$param1" ] ; then
		#rsync -vah --partial -e 'ssh -i '"$filepubkey"' "$param1"  "$destipv6addr_scp":"$param2"
		#mycommand="rsync -vah --partial ""$param1"" ""$destipv6addr_scp"":""$param2""/"" -e 'ssh -i ""$filepubkey""'"
		#mycommand="rsync -vah --partial ""$param1"" ""$param2""/"
		rsync -vah --partial -e "ssh -i ${filepubkey}" "$param1" "$destipv6addr_scp":"$param2"/ 
		#echo "$mycommand"
		#result=$(eval $mycommand)
		cmd=$?
	fi
}


main(){
	local cmd
	local mycommand
	local result
	
	if [ ! -d "$memtemp_local" ] ; then
		mkdir "$memtemp_local"
	fi
	
	rm "$memtemp_local"/*

	while true; do
	
		check_network
		cmd=$?
		myprintf "check network" "$cmd"
		
		if [ "$cmd" -eq 1 ] && [ -f "$filepubkey" ] ; then
			
			#add to know_hosts for firsttime
			ssh -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "rm -r ${memtemp_remote}"
			cmd=$?
			myprintf "remove temp folder at remote" "$cmd"
			
			ssh -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "mkdir ${memtemp_remote}"
			cmd=$?
			myprintf "mkdir temp at remote" "$cmd"

			verify_logged
			cmd=$?
			myprintf "verify active user" "$cmd"
			
			#if verifyresult: no active user -> sync_dir
			if [ "$cmd" -gt 10 ] ; then
				myecho "begin sync dir"
				#sync_dir "$dir_ori" "$dir_dest"
				echo "go to sleep 1"
				sleep "$sleeptime"m
			else
				echo "go to sleep 2"
				sleep "$sleeptime"m
			fi
		else
			echo "go to sleep 00"
			sleep "$sleeptime"m
		fi
	done
	
}

#main
find_list_same_files "/home/dungnt/ShellScript" "/home/backup/sosanh"
sync_file_in_dir "/home/dungnt/ShellScript" "/home/backup/sosanh"
#copy_file_to_remote "/home/dungnt/ShellScript/\` '  @#$%^&( ).sdf" /home/backup/sosanh
