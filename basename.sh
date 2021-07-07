#!/bin/bash

#FILE=/home/dungnt/"ShellScript '' *&^^%'.df"		->ShellScript '' *&^^%'.df
#FILE=/home/dungnt/"ShellScript '' *&^^%'"/		->ShellScript '' *&^^%'
FILE='/home/dungnt/ShellScript/dirtest1/Btc Quantum "(*^*&^ (*&"" 09'


getdirnameFromFullPath () {
	echo $1
	a=$(basename $1)
}

#getdirnameFromFullPath $FILE
echo $FILE
echo "$FILE"
basename "$FILE"
a=$(basename "$FILE")
echo $a

