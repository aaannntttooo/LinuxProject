#!/bin/bash


while read -r line; do
	cut -d ';' -f 1,2,3,4
	echo "test"

done < accounts.csv

mkdir /home/shared

while read -r line; do
 #   cut_output=$(cut -d ';' -f 1,2,3,4 <<< $line)
#    echo "$cut_output test"

    # use the $cut_output variable in another command here
	#cut -d ';' -f 1,2,3,4 | tr ';' '\n' | while read element; do echo -en "$element \n"; done
	IFS=';' read -r nom prenom mail motdepasse <<< "$line"
	 adduser --gecos "$prenom $nom" --disabled-password --force-badname --home "$nom"
	    echo "$nom:$motdepasse" | chpasswd
	    chage -d 0 "$nom"

	mkdir /home/"$nom"/a_sauver ### Creation du dossier 'a_sauver' par user.
	
	mkdir /home/shared/"$nom"  ### Creation du dossier par user dans Shared
	sudo chown "$nom"  /home/shared/"$nom" ###Seul l'utilisateur dont son nom est le fichier peut 
	sudo chmod 755 /home/shared/"$nom"

done < accounts.csv

