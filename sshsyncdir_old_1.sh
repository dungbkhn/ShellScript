#!/bin/bash


shopt -s dotglob
shopt -s nullglob

dir_ori=/home/dungnt/ShellScript/dirtest1
dir_dest=/home/backup/storageBackup

appdir_local=/home/dungnt/ShellScript/sshsyncapp
appdir_remote=/home/backup

memtemp_local="$appdir_local"/.temp
memtemp_remote="$appdir_remote"/.temp

appdir_sha_remote="$appdir_remote"/sha256
file_output_sha=outfile_sha256.txt
file_output_sha_temp=outfile_sha256_temp.txt
truncatefile_inremote=truncatefile_inremote.txt

appdir_trunc_remote="$appdir_remote"/trunc
truncateshellfile=runtrunc.sh

appdir_sha_local="$appdir_local"/sha256
gen256remoteprocess=gen256hash.out
gen256localfile=gen256hash_local.out
gen256localCfile=gen256hash_local.c
sha256localCfile=sha256.c
outfile_sha256_local=outfile_sha256_local.txt
outfile_sha256_local_temp=outfile_sha256_local_temp.txt

compare_listfile_inremote=comparelistfile_remote.sh
dir_contains_uploadfiles="$appdir_local"/remotefiles

destipv6addr="backup@"
destipv6addr_scp="backup@[]"

filepubkey=/home/dungnt/.ssh/id_rsa_backup_58
logtimedir_remote=/home/dungnt/MyDisk_With_FTP/logtime
logtimefile=logtimefile.txt
outputfileforcmp_inremote=outputfile_inremote.txt
uploadlistfile=listfile.txt


sleeptime=5
#for PRINTING
prt=1
#for COMPARE
copyfilesize="10MB"
truncsize=10000000
#for SHA
#//1024*1024 for filesize < 16 M = 16777216
MYSIZE_L1=1048576 
#//16*1024*1024 for filesize < 256 M = 268435456
MYSIZE_L2=16777216 
# //256*1024*1024 others
MYSIZE_L3=268435456

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
	local cmd3
	local result
	local mycommand
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
		
	if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] && [ "$cmd3" -ne 255 ] ; then
		for (( loopforcount=0; loopforcount<21; loopforcount+=1 ));
		do
			result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "bash ${memtemp_remote}/${compare_listfile_inremote} /${listfiles} ${param2} ${outputfile_inremote}")
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
					#if [ "${mtime[$i]}" -lt "${mtime_local[$i]}" ] ; then
					#	echo 'file remote cu hon ---> can append native'
					#else
					#	echo 'append with hash'
					#fi
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
		echo 'begin append 2m'
		rsync -vah --append --time-limit=2 -e "ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i ${filepubkey}" "$param1" "$param2":"$param3"/"$param4"
		cmd=$?
		if [ "$cmd" -eq 0 ] ; then
			echo 'append ends successfully'
			return 0
		elif [ "$cmd" -eq 30 ] ; then
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
			
				result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i /home/dungnt/.ssh/id_rsa_backup_58 backup@192.168.1.58 "netstat -atn 2>&1 | grep ':22 ' 2>&1 | grep 'ESTABLISHED' | wc -l")
				cmd2=$?
				myprintf "run countsshuser" "$cmd2"
				myprintf "num sshuser" "$result"
				
				if [ "$cmd1" -eq 1 ] && [ "$cmd2" -ne 255 ] && [ "$result" -lt 2 ] ; then
					#thoat vong lap for
					break
				else
					sleep 15			
				fi	
			done
		else
			echo 'nghi dai ko ro loi cua rcync '"$cmd"
			return 1
		fi
	done
}

append_file_with_hash_checking(){
	local param1=$1
	local param2=$2
	local filename=$(basename "$param1")
	local mytemp="$memtemp_local"
	local mycommand
	local result
	local cmd
	local cmd1
	local cmd2
	local cmd3
	local rsyncstring
	local filesize
	local shasize
	local shatruncnum
	local shatruncnum_modulo
	local shalevel
	local uploadfile="$uploadlistfile"
	local count
	local loopforcount
	local shatempsize
	
	cmd1=255
	cmd2=255
	cmd3=255
	count=0
	
	#thu ket noi mang
	while [ "$cmd1" -eq 255 ] || [ "$cmd2" -eq 255 ] || [ "$cmd3" -eq 255 ] ; do
		
		sleep 1
		
		result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "rm ${appdir_sha_remote}/${file_output_sha}")
		cmd1=$?
		
		myprintf "ssh remove file_output_sha" "$cmd1"
		
		result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "rm ${appdir_sha_remote}/${file_output_sha_temp}")
		cmd2=$?
		
		myprintf "ssh remove file_output_sha_temp" "$cmd2"
		
		result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "rm ${appdir_sha_remote}/${uploadfile}")
		cmd3=$?
		
		myprintf "ssh remove old upload shafile" "$cmd3"
		
		count=$(($count + 1))

		if [ "$count" -eq 10 ] ; then
			echo 'ko the ket noi, nghi dai'
			return
		fi
		
	done
	
	
	filesize=$(wc -c "$param1" | awk '{print $1}')
	
	if [ -f "$param1" ] && [ "$filesize" -gt 0 ] ; then
						
		if [ "$filesize" -lt "$MYSIZE_L2" ] ; then
			shasize="$MYSIZE_L1"
			shalevel=1
		elif [ "$filesize" -lt "$MYSIZE_L3" ] ; then
			shasize="$MYSIZE_L2"
			shalevel=2
		else
			shasize="$MYSIZE_L3"
			shalevel=3
		fi
		
		echo 'filesize'"$filesize"
		echo 'level'"$shalevel"
		shatruncnum=$(($filesize / $shasize))
		shatruncnum_modulo=$(($filesize % $shasize))
		
		if [ "$shatruncnum_modulo" -ne 0 ] ; then
			shatruncnum=$(($shatruncnum + 1))
		fi
		
		echo "shatruncnum:""$shatruncnum"
		
		echo "$shalevel" > "$mytemp"/"$uploadfile"
		echo "$shatruncnum" >> "$mytemp"/"$uploadfile"
		echo "$param2"/"$filename" >> "$mytemp"/"$uploadfile"
		
		cmd=1
		count=0
		
		while [ "$cmd" -ne 0 ] ; do
			if [ "$count" -eq 8 ] ; then
				echo 'rsync error, ko the up truncatefile len remote, nghi dai'
				return
			fi
			
			sleep 1
			rsync -vah --partial -e "ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i ${filepubkey}" "$mytemp"/"$uploadfile" "$destipv6addr_scp":"$appdir_sha_remote"/ 
			cmd=$?
			
			count=$(($count + 1))
		done
		
		echo 'up truncatefile len remote ok'
		
		###############################################################3
		#kiem tra q/tr generate sha256file o phia remote
		count=0
		shatempsize=0
		while true ; do
			if [ "$count" -eq 7 ] ; then
				echo 'kiem tra tempfile qua timeout, nghi dai'
				return
			fi
			
			#trung binh gen256sha process ngu dai nhat 10s trong dk binh thuong
			sleep 10
			
			result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "find ${appdir_sha_remote} -maxdepth 1 -type f -name ${file_output_sha_temp}")
			cmd=$?
			
			#ko loi thuc thi ssh
			if [ "$cmd" -eq 0 ] ; then
				#tim thay tempfile
				echo "timthaytempfile ko?:""$result"
				if [ "$result" ] ; then
					#tinh kich thuoc shatempsize, save vao shatempsize
					#thu 20 lan truoc khi ko the lay kichthuoc shatempsize
					for (( loopforcount=0; loopforcount<=20; loopforcount+=1 ));
					do
						sleep 2
						
						result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "pidof ${gen256remoteprocess}")
						cmd1=$?
						if [ "$cmd1" -eq 0 ] && [ ! "$result" ] ; then
							echo "cmd1: ""$cmd1"" result: ""$result"' process dung bat thuong, nghi dai 0'
							return
						fi
						
						result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "wc -c ${appdir_sha_remote}/${file_output_sha_temp}")
						cmd=$?
						
						#neu chay ssh thanh cong
						if [ "$cmd1" -eq 0 ] && [ "$cmd" -ne 255 ] ; then
							#thoat vong lap for
							break
						else
							sleep 13
						fi
					done
					
					#lay duoc kich thuoc file,=0 cung ko sao vi cpu nang se ko update file size
					if [ "$cmd" -eq 0 ] ; then
						echo 'gan lai count'
						count=0
					#ko lay duoc kich thuoc file
					#outputfiletemp mat--->outputsha da sinh ra
					#hoac process nghi 45s hoac process chet
					else						
						#kiem tra da sinh output 256sha chua
						for (( loopforcount=0; loopforcount<=20; loopforcount+=1 ));
						do
							sleep 2
							result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "find ${appdir_sha_remote} -maxdepth 1 -type f -name ${file_output_sha}")
							cmd=$?
							#neu chay ssh thanh cong
							if [ "$cmd" -eq 0 ] ; then
								#thoat vong lap for
								break
							else
								sleep 13
							fi
						done
						echo 'mat temp file dot ngot hoac shagen da sinh ra:'"$result"
						#neu shafile generated
						if [ "$cmd" -eq 0 ] && [ "$result" ] ; then
							#thoat vong lap while
							echo 'file sha generated roi do 1'
							break
						#neu process stopped
						else
							echo 'process stopped 45s, nghi dai 2'
							return
						fi
					fi
				#ko tim thay tempfile
				else
					#co 2 TH:1.process gen sha stopped; 2. shafile generated
					for (( loopforcount=0; loopforcount<=20; loopforcount+=1 ));
					do
						sleep 2
						result=$(ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "find ${appdir_sha_remote} -maxdepth 1 -type f -name ${file_output_sha}")
						cmd=$?
						#neu chay ssh thanh cong
						if [ "$cmd" -eq 0 ] ; then
							#thoat vong lap for
							break
						else
							sleep 13
						fi
					done
					
					#neu shafile generated
					if [ "$cmd" -eq 0 ] && [ "$result" ] ; then
						#thoat vong lap while
						echo 'file sha generated ngay tu dau'
						break
					#neu process stopped
					else
						echo 'process stopped in 45s, nghi dai'
						return
					fi
				fi
			#loi thuc thi ssh, thu tiep vai lan
			else
				echo 'loi thuc thi ssh'
				count=$(($count + 1))
			fi
		done
		
		###############################################################
		
		for (( loopforcount=0; loopforcount<=20; loopforcount+=1 ));
		do
			rsync -vah --inplace -e "ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i ${filepubkey}" "$destipv6addr_scp":"$appdir_sha_remote"/"$file_output_sha" "$mytemp"/ 
			cmd=$?
			if [ "$cmd" -eq 0 ] ; then
				break
			else
				sleep 15
			fi
		done
		
		filesize=$(wc -c "$mytemp"/"$file_output_sha" | awk '{print $1}')
		
		#lay sha256outputfile thanh cong va ko chua xau ######
		if [ "$cmd" -eq 0 ] && [ "$filesize" -gt 20 ] ; then
			echo 'rsync ok,lay shaoutput file success'
			#gcc sha.out
			echo "$appdir_sha_local"/"$gen256localfile"
			if [ ! -f "$appdir_sha_local"/"$gen256localfile" ] ; then
				cd "$appdir_sha_local"/
				gcc "$gen256localCfile" "$sha256localCfile" -D_LARGEFILE_SOURCE=1 -D_FILE_OFFSET_BITS=64 -o "$gen256localfile"
				if [ "$?" -ne 0 ] ; then
					echo 'loi bien dich gcc, nghi dai'
					return
				fi
			fi
			echo "gen local sha256 file"
			echo "$shalevel" > "$mytemp"/"$uploadfile"
			echo "$shatruncnum" >> "$mytemp"/"$uploadfile"
			echo "$param1" >> "$mytemp"/"$uploadfile"
			#echo "./""$gen256localfile"" ""$mytemp""/""$uploadfile"" ""$mytemp""/""$outfile_sha256_local"" ""$mytemp""/""$outfile_sha256_local_temp"
			cd "$appdir_sha_local"/
			./"$gen256localfile" "$mytemp"/"$uploadfile" "$mytemp"/"$outfile_sha256_local" "$mytemp"/"$outfile_sha256_local_temp"

			echo "cmp sha256 files"
			#compare get diff line
			result=$(cmp "$mytemp"/"$outfile_sha256_local" "$mytemp"/"$file_output_sha")
			cmd=$?
			if [ "$cmd" -eq 0 ] ; then
				echo 'hai file giong nhau'
			elif [ "$cmd" -eq 1 ] ; then
				shatruncnum=$(echo "$result" | awk '{print $7}')
				filesize=$(($shasize * ($shatruncnum - 1)))
				echo "size shrink:""$filesize"
				
				for (( loopforcount=0; loopforcount<=20; loopforcount+=1 ));
				do
					echo "$filesize" > "$mytemp"/"$truncatefile_inremote"
					echo "$param2"/"$filename" >> "$mytemp"/"$truncatefile_inremote"
					rsync -vah --inplace -e "ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i ${filepubkey}" "$mytemp"/"$truncatefile_inremote" "$destipv6addr_scp":"$memtemp_remote"/ 
					cmd1=$?
					rsync -vah --inplace -e "ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i ${filepubkey}" "$dir_contains_uploadfiles"/"$truncateshellfile" "$destipv6addr_scp":"$appdir_trunc_remote"/ 
					cmd2=$?
					ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$filepubkey" "$destipv6addr" "bash ${appdir_trunc_remote}/${truncateshellfile} ${memtemp_remote}/${truncatefile_inremote}"
					cmd3=$?
					
					if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] && [ "$cmd3" -eq 0 ] ; then
						break
					else
						sleep 15
					fi
				done
				
				if [ "$cmd1" -eq 0 ] && [ "$cmd2" -eq 0 ] && [ "$cmd3" -eq 0 ] ; then
					#result=$(rsync -vah --append -e "ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i ${filepubkey}" "$param1" "$destipv6addr_scp":"$param2"/"$filename" )
					append_native_file "$param1" "$destipv6addr_scp" "$param2" "$filename"
				else
					echo 'ssh fail, truncate error, nghi dai'
				fi
			else
				echo 'cmp fail, nghi dai'
			fi
		else
			echo 'rsync fail,lay shaoutput file fail,or output chua ######, nghi dai'
		fi
	else
		echo 'big error,ko thay file, nghi dai'
	fi
	
}

copy_file() {
	local param1=$1
	local param2=$2
	local filename=$(basename "$param1")
	
	append_native_file "$param1" "$destipv6addr_scp" "$param2" "$filename"
	return "$?"
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
sync_file_in_dir "/home/dungnt/ShellScript" "/home/backup/sosanh"
#append_file_with_hash_checking "/home/dungnt/ShellScript/\` '  @#$%^&( ).sdf" /home/backup/sosanh
#append_file_with_hash_checking /home/dungnt/ShellScript/file_nhieu_mb.txt /home/backup/sosanh
#append_file_with_hash_checking /media/dungnt/BBC4-B189/file300mb.txt /home/backup
#append_file_with_hash_checking /home/dungnt/ShellScript/test.sh /home/backup/sosanh

