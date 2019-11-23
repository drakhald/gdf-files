#! /bin/bash
#Jelszó ellenőrző

#Ha egy, vagy több paramétert kapunk
if [ $# -ge 1 ]
then
        #akkor az első paraméter lesz a keresett jelszó
        pwd=$1
else
        #különben a nemtom
        pwd='nemtom'
fi

echo 'Jelszó?'
#olvasunk a konzolról
while read i
do
        #ha nem üres entert ütöttünk
        if ! [ -z $i ]
        then
                #ha egyezik
                if [ $i == $pwd ]
                then
                        echo 'Oké'
                        break
                        exit 0
                else
                        echo 'Jelszó?'
                fi
        else
                echo 'Jelszó?'
        fi
done
