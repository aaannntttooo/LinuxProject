#!/bin/bash




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
	sudo chown "$nom"  /home/shared/"$nom" ###Seul l'utilisateur dont son nom est le fichier peut modifier le dossier 
	sudo chmod 755 /home/shared/"$nom"

done < accounts.csv



### MISE EN PLACE DE L'ENVOIE DU MAIL
sudo apt-get upgrade ssmtp
#echo "Bonjour $prenom,Votre mot de passe : $motdepasse"| mail  -s "Info de co" 'antonsoquetpro@gmail.com'



read -p "Enter your e-mail: " loginMail
read -p "Enter your Password: " pwdMail







# Set the new contents for the ssmtp.conf file
new_config="
mailhub=smtp.office365.com:587
FromLineOverride=YES
TLS_CA_File=/etc/pki/tls/certs/ca-bundle.crt
AuthUser=$loginMail
AuthPass=$pwdMail
UseSTARTTLS=YES
"

# Overwrite the ssmtp.conf file with the new configuration
sudo echo "$new_config" | sudo tee /etc/ssmtp/ssmtp.conf > /dev/null

### FIN DE LA MISE EN PLACE DE l'ENVOIE DU MAIL

### MISE EN PLACE DU PARFEU ###
sudo apt-get upgrade iptables


#sudo iptables -A INPUT -p tcp --dport 21 -j DROP
#sudo iptables -A OUTPUT -p tcp --sport 21 -j DROP

iptables -I INPUT -s 192.168.1.100 -p tcp --dport 20,21 -j REJECT
iptables -I INPUT -s 192.168.1.100/24 -p tcp --dport 20,21 -j REJECT




sudo iptables -A INPUT -p udp -j DROP
sudo iptables -A OUTPUT -p udp -j DROP

service iptables save
### FIN DE MISE EN PLACE DU PARFEU

#sudo iptables-save > /etc/iptables/rules.v4
