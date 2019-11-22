#! /bin/bash
#Faktoriális számító program

if [[ $# -eq 0 ]] 
then
	echo "Program használata $0 SZÁM[...]"
	exit -1
fi

for i in $@
do
	if [[ $i =~ [0-9]+ ]]
	then
		R=1
		for (( x=$i; x>0; x-- ))
		do
			R=$(($R*$x))
		done
		echo $i faktoriálisa $R
	else
		echo $i faktoriálisa NaN, $i nem egész
	fi
done
