#!/bin/bash

shopt -s dotglob
shopt -s nullglob

dir_ori=/home/dungnt/ShellScript/dirtest1
dir_dest=/home/backup/storageBackup

appdir_local=/home/dungnt/ShellScript/sshsyncapp
appdir_remote=/home/backup

memtemp_local="$appdir_local"/.temp
memtemp_remote="$appdir_remote"/.temp

compare_listfile_inremote=comparelistfile_remote.sh
getmd5hash_inremote=getmd5hash_inremote.sh
dir_contains_uploadfiles="$appdir_local"/remotefiles

destipv6addr="backup@"
destipv6addr_scp="backup@[]"

filepubkey=/home/dungnt/.ssh/id_rsa_backup_58
logtimedir_remote=/home/dungnt/MyDisk_With_FTP/logtime
logtimefile=logtimefile.txt
#file mang thong tin ds file trong dir --> up len de so sanh
outputfileforcmp_inremote=outputfile_inremote.txt

uploadmd5hashfile=md5hashfile_fromlocal.txt


sleeptime=5
#for PRINTING
prt=1
#for COMPARE
copyfilesize="500MB"
truncsize=500000000

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
	
	#trang thai mac dinh=1:ko co mang
	state=1
	
	ping -c 1 -W 1 -4 google.com
	cmd=$?
	
	if [ "$cmd" -eq 0 ] ; then
		#co mang
		state=0
	fi 
	
	if [ "$state" -eq 0 ] ; then
	
		ping -c 1 -W 1 -4 vnexpress.net
		cmd=$?

		if [ "$cmd" -eq 0 ] ; then
			#co mang
			state=0
		fi 
		
	fi

	#0: co mang
	#1: ko co mang
	return "$state"
}

#------------------------------ VERIFY ACTIVE USER --------------------------------
verify_logged() {
	#mac dinh la ko thay active user 
	local kq
	local result
	local cmd
	local line
	local value
	local curtime
	local delaytime
	
	kq=1
	
	if [ -f "$filepubkey" ] ; then
	
		result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "tail ${logtimedir_remote}/${logtimefile}")
		cmd=$?
		echo "$result"
		
		if [ "$cmd" -eq 0 ] ; then
				#echo 'tim thay' $logtimefile
				if [ "$result" ] ; then
					curtime=$(($(date +%s%N)/1000000))
					#printf 'curtime:%s\n' "$curtime"
					value=$(echo "${result##*$'\n'}")
					printf 'value:%s\n' "$value"
					delaytime=$(( ( $curtime - $value ) / 60000 ))
					printf 'delaytime:%s\n' "$delaytime"" minutes"
					if [ "$delaytime" -gt 6 ] ; then
						#ko thay active web user
						kq=0
					else
						#tim thay co active web user
						kq=255
					fi
				fi
		fi
	fi

	#1: run function fail
	#0: no active web user found
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
	local cmd3
	local result
	local pathname
	local filesize
	local md5hash
	local mtime
	local mtime_temp
	local listfiles="listfilesforcmp.txt"
	local outputfile_inremote="$outputfileforcmp_inremote"
	local loopforcount
	
	rm "$mytemp"/*

	cd "$param1"/
	
	touch "$mytemp"/"$listfiles"
	
	#ERROR: co the co loi khi file vua bi xoa truoc khi lay filezise....
	#giai quyet: lay filesize cuoi cung, neu =0 --> bi xoa roi
	for pathname in ./* ;do
		if [ -d "$pathname" ] ; then 
			printf "%s/%s/0/0/0\n" "$pathname" "d" >> "$mytemp"/"$listfiles"
		else
			md5hash=$(head -c 1024 "$pathname" | md5sum | awk '{ print $1 }')
			#md5tailhash=$(get_src_content_file_md5sum "$pathname")
			mtime_temp=$(stat "$pathname" --printf='%y\n')
			mtime=$(date +'%s' -d "$mtime_temp")
			filesize=$(wc -c "$pathname" | awk '{print $1}')
			#printf "%s/%s/%s/%s/%s/%s\n" "$pathname" "f" "$filesize" "$md5hash" "$md5tailhash" "$mtime" >> "$mytemp"/"$listfiles"
			printf "%s/%s/%s/%s/%s\n" "$pathname" "f" "$filesize" "$md5hash" "$mtime" >> "$mytemp"/"$listfiles"
		fi
	done

	cd "$workingdir"/
	
	result=$(scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" -p "$mytemp"/"$listfiles" "$destipv6addr_scp":"$memtemp_remote"/)
	cmd1=$?
	myprintf "scp 1 listfile" "$cmd1"
			
	result=$(scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" -p "$dir_contains_uploadfiles"/"$compare_listfile_inremote" "$destipv6addr_scp":"$memtemp_remote"/)
	cmd2=$?
	myprintf "scp 1 shellfile" "$cmd2"

	result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "rm ${memtemp_remote}/${outputfile_inremote}")
	cmd3=$?
	
	myprintf "ssh remove old outputfile" "$cmd3"
	pathname=$(echo "$param2" | tr -d '\n' | xxd -pu -c 1000000)
	
	if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] && [ "$cmd3" -ne 255 ] ; then
		for (( loopforcount=0; loopforcount<21; loopforcount+=1 ));
		do
			result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "bash ${memtemp_remote}/${compare_listfile_inremote} /${listfiles} ${pathname} ${outputfile_inremote}")
			cmd=$?
			myprintf "ssh generate new outputfile" "$cmd"
			if [ "$cmd" -eq 0 ] ; then
				break
			else
				sleep 1
			fi
		done
		
		if [ "$cmd" -eq 0 ] ; then
			result=$(scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" -p "$destipv6addr_scp":"$memtemp_remote"/"$outputfile_inremote" "$mytemp"/)
			cmd=$?
			myprintf "scp getback outputfile" "$cmd"
		fi
	fi
}


sync_file_in_dir(){
	local param1=$1
	local param2=$2
	local mytemp="$memtemp_local"
	local outputfile_inremote="$outputfileforcmp_inremote"
	local cmd
	local findresult
	local count
	local total
	local beforeslash
	local afterslash_1
	local afterslash_2
	local afterslash_3
	local afterslash_4
	local afterslash_5
	local afterslash_6
	local afterslash_7
	
	# declare array
	declare -a name
	declare -a size
	declare -a md5hash
	declare -a mtime
	declare -a mtime_local
	declare -a apporcop
	
	# declare array
	local countother
	declare -a nameother
	
	find_list_same_files "$param1" "$param2"
	
	if [ -f "$mytemp"/"$outputfile_inremote" ] ; then
		count=0
		countother=0
		total=0
		while IFS=/ read beforeslash afterslash_1 afterslash_2 afterslash_3 afterslash_4 afterslash_5 afterslash_6 afterslash_7
		do
			if [ "$afterslash_1" != "" ] ; then
				if [ "$afterslash_2" -eq 0 ] ; then
					name[$count]="$afterslash_1"
					size[$count]="$afterslash_4"
					md5hash[$count]="$afterslash_5"
					mtime[$count]="$afterslash_6"
					mtime_local[$count]="$afterslash_7"
					echo "needappend:""${name[$count]}""-----""${size[$count]}""-----""${md5hash[$count]}""-----""${mtime[$count]}"
					apporcop[$count]=1
					count=$(($count + 1))
				elif [ "$afterslash_2" -eq 4 ] || [ "$afterslash_2" -eq 5 ] ; then
					name[$count]="$afterslash_1"
					size[$count]="$afterslash_4"
					md5hash[$count]="$afterslash_5"
					mtime[$count]="$afterslash_6"
					mtime_local[$count]="$afterslash_7"
					echo "needcopy:""${name[$count]}""-----""${size[$count]}""-----""${md5hash[$count]}""-----""${mtime[$count]}"
					apporcop[$count]=45
					count=$(($count + 1))
				else
					nameother[$countother]="$afterslash_1"
					countother=$(($countother + 1))
				fi
				
				if [ "$afterslash_2" -ne 3 ] ; then
					total=$(($total + 1))
				fi
			else
				echo "--------------------""$total"" files received valid---------------------"
			fi
		done < "$mytemp"/"$outputfile_inremote"
		
		count=0
		for i in "${!nameother[@]}"
		do
			printf '%s\n' "${nameother[$i]}" 
			count=$(($count + 1))
		done
		echo 'file ko duoc tinh------------'"$count"
		
		count=0
		for i in "${!name[@]}"
		do
			findresult=$(find "$param1" -maxdepth 1 -type f -name "${name[$i]}")
			
			cmd=$?
			#neu tim thay
			if [ "$cmd" -eq 0 ] && [ "$findresult" ] ; then
				#echo "nhung file giong ten nhung khac attribute:""$findresult"
				if [ "${apporcop[$i]}" -eq 1 ] ; then
					#file local da bi modify (ko ro vi tri bi modify) ---> append with hash
					echo "nhung file needappend:""$findresult"" mtimelocal: ""${mtime_local[$i]}"" mtime: ""${mtime[$i]}"
				else
					echo "nhung file needcopy:""$findresult"
				fi
			#neu ko tim thay
			else
				printf '**********************************file not found\n'
			fi
			count=$(($count + 1))
		done
		
		echo "--------------------""$count"" files can append hoac copy ---------------------"
		
		return 0
	else
		return 1
	fi
}
	
#------------------------------ APPEND FILE --------------------------------

append_native_file(){
	local param1=$1
	local param2=$2
	local param3=$3
	local param4=$4
	local result
	local cmd
	local cmd1
	local cmd2
	local loopforcount
	
	while true; do
		for (( loopforcount=0; loopforcount<21; loopforcount+=1 ));
		do		
			#vuot timeout
			if [ "$loopforcount" -eq 20 ] ;  then
				echo 'append timeout, nghi dai'
				return 1
			fi
		
			verify_logged
			cmd1=$?
			myprintf "verify active user" "$cmd1"
		
			result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i /home/dungnt/.ssh/id_rsa_backup_58 backup@192.168.1.58 "netstat -atn | grep ':22 ' | grep 'ESTABLISHED' | wc -l")
			cmd2=$?
			myprintf "run countsshuser" "$cmd2"
			myprintf "num sshuser" "$result"
			
			if [ "$cmd1" -eq 0 ] && [ "$cmd2" -ne 255 ] && [ "$result" -lt 2 ] ; then
				#thoat vong lap for
				break
			else
				sleep 15			
			fi	
		done
		#ERORRRRRRRRRRRRRR:rsync append 2 m --->loi:file cop bi sai o vi tri append
		echo 'begin append 2m'
		rsync -vah --append --time-limit=2 -e "ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i ${filepubkey}" "$param1"/"$param4" "$param2":"$param3"/"$param4"
		cmd=$?
		if [ "$cmd" -eq 0 ] ; then
			echo 'append ends successfully'
			return 0
		elif [ "$cmd" -ne 30 ] ; then
			echo 'nghi dai ko ro loi cua rcync '"$cmd"
			return 1
		fi
		
	done
}

append_file_with_hash_checking(){
	local param1=$1
	local param2=$2
	local filename=$3
	local filesize_remote=$4
	local hashlocalfile
	local hashremotefile
	local result
	local cmd
	local cmd1
	local cmd2
	local count
	local filesize
	local loopforcount
	local temphashfilename="tempfile.totalmd5sum.being"
	local tempfilename
	
	rm "$memtemp_local"/"$temphashfilename"
	
	tempfilename=$(echo "$param2""/""$filename" | tr -d '\n' | xxd -pu -c 1000000)
	
	for (( loopforcount=0; loopforcount<21; loopforcount+=1 ));
	do		
		#vuot timeout
		if [ "$loopforcount" -eq 20 ] ;  then
			echo 'append with hash timeout, nghi dai'
			return 1
		fi
		
		result=$(scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" -p "$dir_contains_uploadfiles"/"$getmd5hash_inremote" "$destipv6addr_scp":"$memtemp_remote"/)
		cmd1=$?
		myprintf "scp 1 shellmd5hashfile" "$cmd1"
	
		result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i /home/dungnt/.ssh/id_rsa_backup_58 backup@192.168.1.58 "bash ${memtemp_remote}/${getmd5hash_inremote} ${tempfilename}")
		cmd2=$?
		echo "get ""$cmd2"" md5sum:""$result"
		
		if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] ; then
			#thoat vong lap for
			break
		else
			sleep 15			
		fi	
	done
		
	if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] ; then
		#thoat vong lap for
		hashremotefile=$(echo "$result" | awk '{ print $1 }')
		hashlocalfile=$(md5sum "$param1"/"$filename" | awk '{ print $1 }')
		#echo "$hashlocalfile"
		if [ "$hashlocalfile" == "$hashremotefile" ] ; then
			echo 'has same md5hash'
			return 0
		else
			filesize=$(wc -c "$param1"/"$filename" | awk '{print $1}')
	
			if [ -f "$param1"/"$filename" ] && [ "$filesize" -gt 0 ] ; then
				truncnum=$(( ( $filesize_remote / $truncsize ) + 1 ))
				echo 'truncnum ' "$truncnum"
				dd if="$param1"/"$filename" of="$memtemp_local"/"$temphashfilename" bs="$copyfilesize" count="$truncnum" skip=0
				truncate -s "$filesize_remote" "$memtemp_local"/"$temphashfilename"
				hashlocalfile=$(md5sum "$memtemp_local"/"$temphashfilename" | awk '{ print $1 }')
				if [ "$hashlocalfile" == "$hashremotefile" ] ; then
					echo 'has same md5hash after truncate'
					return 0
				else
					echo 'has same md5hash after truncate-->copy'
					return 1
				fi
			
			else
				echo 'big error,ko thay file, nghi dai'
				return 1
			fi
		fi
	fi	
}

copy_file() {
	local param1=$1
	local param2=$2
	local filename=$3
	
	append_native_file "$param1" "$destipv6addr_scp" "$param2" "$filename"
	return "$?"
}


main(){
	local cmd
	local result
	
	if [ ! -d "$memtemp_local" ] ; then
		mkdir "$memtemp_local"
	fi
	
	rm "$memtemp_local"/*

	while true; do
	
		check_network
		cmd=$?
		myprintf "check network" "$cmd"
		
		if [ "$cmd" -eq 0 ] && [ -f "$filepubkey" ] ; then
			
			#add to know_hosts for firsttime
			result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "mkdir ${memtemp_remote}")
			cmd=$?
			myprintf "mkdir temp at remote" "$cmd"

			verify_logged
			cmd=$?
			myprintf "verify active user" "$cmd"
			
			break
			
			#if verifyresult: no active user -> sync_dir
			if [ "$cmd" -gt 10 ] ; then
				myecho "begin sync dir"
				#sync_dir "$dir_ori" "$dir_dest"
				echo "go to sleep 1"
				#sleep "$sleeptime"m
			else
				echo "go to sleep 2"
				#sleep "$sleeptime"m
			fi
		else
			echo "go to sleep 00"
			#sleep "$sleeptime"m
		fi
	done
	
}

#main
#sync_file_in_dir "/home/dungnt/ShellScript" "/home/backup/biết sosanh"
#append_file_with_hash_checking "/home/dungnt/ShellScript" "/home/backup/biết sosanh" "\` '  @#$%^&( ).sdf" 99
#append_file_with_hash_checking /media/dungnt/BBC4-B189 /home/backup file300mb.txt 546537472
#append_file_with_hash_checking /home/dungnt/ShellScript "/home/backup/biết sosanh" mySync_final.sh 13506
copy_file /media/dungnt/BBC4-B189 /home/backup file300mb.txt
