#! /bin/bash
#Faktoriális számító program

if [[ $# -eq 0 ]] 
then
	echo "Program használata $0 SZÁM[...]"
	exit -1
fi

for i in $@
do
	R=1
	C=1
	while [ $C -le $i ]
	do
		R=$(($R*$C))
		C=$(($C+1))
	done
	echo $i faktoriálisa $R
done
