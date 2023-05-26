#!/bin/bash

MAIL_SERVER=$1
MAIL_LOGIN=$2
MAIL_PWD=$3 
MAIL_LOGINSED=$(echo "$MAIL_LOGIN" | sed 's/@/%40/g')


mkdir /home/shared


ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "mkdir saves"

### FIN DE LA MISE EN FONCTION D'ECLIPSE


file="tamponCron.txt"
touch $file
crontab -u isen -l > $file

while read -r line; do	
	IFS=';' read -r nom prenom mail motdepasse <<< "$line"	
 	login=${nom:0:1}"$prenom"
	login=$(echo "$login" | sed 's/ /_/g')
	echo "$login"
	useradd -m "$login" --home /home/"$login" --shell /bin/bash
	 echo "$login:$motdepasse" | chpasswd
	 chage -d 0 "$login"
#	deluser --remove-home "$login"
	mkdir /home/"$login"/a_sauver ### Creation du dossier 'a_sauver' par user.	
	mkdir /home/shared/"$login"  ### Creation du dossier par user dans Shared
	sudo chown "$login"  /home/shared/"$login" ###Seul l'utilisateur dont son nom est le fichier peut modifier le dossier 
	sudo chmod 755 /home/shared/"$login"
	
	#tar -czf /home/"$login"/save_"$login".tgz /home/"$login"/a_sauver
	#scp -i /home/isen/.ssh/id_rsa /home/"$login"/save_"$login".tgz asoque25@10.30.48.100:~/saves
	line="0 23 * * 1-5 isen tar -czf /home/"$login"/save_"$login".tgz /home/"$login"/a_sauver;scp -i /home/isen/.ssh/id_rsa /home/"$login"/save_"$login".tgz asoque25@10.30.48.100:~/saves;rm  /home/"$login"/save_"$login".tgz"
	echo "$line" >> $file

	# Commande pour l'envoie du mail depuis le server
	TO="$mail"
	SUBJECT="Creation de compte"
	BODY="Bonjour $nom $prenom, 
Voici vos informations de connexion : 
Nom d'utilisateur : $login   
Mot de passe :$motdepasse  
Veuillez changer votre mot de passe lors de votre premiere connexion."

        ssh -n -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "mail --subject \"$SUBJECT \" --exec \"set sendmail=smtp://$MAIL_LOGINSED:$MAIL_PWD@smtp.$MAIL_SERVER\" --append \"From:$MAIL_LOGIN\" \"$mail\" <<<\"$BODY\" "


done < <(tail -n +2 accounts.csv)


crontab -u isen $file
rm "$file"


###DEBUT DU MONITORING
	file="tamponCron.txt"
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "touch $file"
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "crontab -u isen -l > $file"
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "touch ressources.log"
        CPU_LOAD=$(ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "top -bn1 | grep \"Cpu(s)\" | awk \'{print $2 + $4}\'")
	MEMORY_LOAD=$(ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "free | awk \'/Mem/ {print $3/$2 * 100}\'")
	current_date=$(date +"%Y-%m-%d")
	current_time=$(date +"%H:%M:%S")
#	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100
	line="0 23 * * 1-5 echo \"$current_date $current_time CPU\: $CPU_LOAD%  Memory\: $MEMORY_LOAD%\" >> ressources.log "
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "crontab -u $file"
        ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "rm $file"

echo "Fin monitoring"


#INSTALLATION D' ECLIPSE
#apt install wget
#wget https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2021-09/R/eclipse-java-2021-09-R-linux-gtk-x86_64.tar.gz -O eclipse.tar.gz
#tar -xf eclipse.tar.gz
#mv eclipse /home
#chmod 775 /home/eclipse
#rm eclipse.tar.gz




#sudo apt-get upgrade iptables

iptables-legacy -t filter -A INPUT -p tcp --dport 20 -j DROP
iptables-legacy -t filter -A INPUT -p tcp --dport 21 -j DROP
iptables-legacy -t filter -A INPUT -p udp -j DROP

sudo iptables-legacy -t filter -A OUTPUT -p tcp --dport 20 -j DROP
sudo iptables-legacy -t filter -A OUTPUT -p tcp --dport 21 -j DROP
sudo iptables-legacy -t filter -A OUTPUT -p udp -j DROP

sudo iptables-legacy -t filter -A FORWARD -p tcp --dport 20 -j DROP
sudo iptables-legacy -t filter -A FORWARD -p tcp --dport 21 -j DROP
sudo iptables-legacy -t filter -A FORWARD -p udp -j DROP

### FIN DE MISE EN PLACE DU PARFEU

