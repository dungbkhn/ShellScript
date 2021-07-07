#!/bin/bash
 
shopt -s dotglob
shopt -s nullglob

param1=$1
file_ori=/home/dungnt/ShellScript/mySync_final.sh

modtime1=$(stat "$param1" --printf='%y\n')
modtime2=$(stat "$file_ori" --printf='%y\n')
stat "$param1" --printf='%y\n'
stat "$file_ori" --printf='%y\n'
echo '-------------------------------------------'
#num1=$(date +'%s%N' -d "$modtime1")
num1=$(date +'%s' -d "$modtime1")
num2=$(date +'%s' -d "$modtime2")
echo "$num1"
echo "$num2"
if [ "$num2" -gt "$num1" ] ;then
	echo '1:'"$file_ori"" sua noi dung muon hon ""$param1"
else
	echo '2:'"$file_ori"" sua noi dung som hon ""$param1"
fi
