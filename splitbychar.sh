#!/bin/bash

#Read the string value
text="Enter book name, author name, price by separating comma"

# Set comma as delimiter
IFS=','

#Read the split words into an array based on comma delimiter
read -a strarr <<< "$text"

len=${#strarr[@]}

echo "$len"

len=$(( $len - 1 ))

echo "$len"

bn=$(echo "${strarr[0]}" | xargs)

an=$(echo "${strarr[1]}" | xargs)

pr=$(echo "${strarr[$len]}" | xargs)

#Print the splitted words
echo "Book Name : $bn"
echo "Author Name : $an"
echo "Price : $pr"
