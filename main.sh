#!/bin/bash

MAIL_SERVER=$1
MAIL_LOGIN=$2
MAIL_PWD=$3 
MAIL_LOGINSED=$(echo "$MAIL_LOGIN" | sed 's/@/%40/g')



mkdir /home/shared

### TELECHARGEMENT D'ECLIPSE ET MISE EN SERVICE
# wget -O eclipse.tar.gz <https://www.eclipse.org/downloads/download.php?file=/oomph/epp/2023-03/R/eclipse-inst-jre-win64.exe>

sudo tar -xf eclipse.tar.gz -C /opt/

# Set permissions
sudo chown -R root:root /opt/eclipse
sudo chmod -R +r /opt/eclipse

sudo chmod +x /usr/share/applications/eclipse.desktop


ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "mkdir saves"

### FIN DE LA MISE EN FONCTION D'ECLIPSE

### INSTALLATION DE SWAKS POUR L'ENVOIE DU MAIL
apt-get install swaks


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
	
	tar -czf /home/"$login"/save_"$login".tgz /home/"$login"/a_sauver
	scp -i /home/isen/.ssh/id_rsa /home/"$login"/save_"$login".tgz asoque25@10.30.48.100:~/saves


	# Commande pour l'envoie du mail depuis le server
	TO="$mail"
	SUBJECT="Creation de compte"
	BODY="Bonjour $nom $prenom, 
Voici vos informations de connexion : 
Nom d'utilisateur : $login   
Mot de passe :$motdepasse  
Veuillez changer votre mot de passe lors de votre premiere connexion."
#	
        ssh -n -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "mail --subject \"$SUBJECT \" --exec \"set sendmail=smtp://$MAIL_LOGINSED:$MAIL_PWD@smtp.$MAIL_SERVER\" --append \"From:$MAIL_LOGIN\" antonsoquet@gmail.com <<<\"$BODY\" "



done < <(tail -n +2 accounts.csv)

### MISE EN PLACE DE LA SOUVEGARDE DES FICHIERS DES UTILISATEURS SUR LE SERVEUR

# Compress the contents of a_sauver directory to .tgz format
# nom = "Agnes"  
#  tar -czf /home/Agnes/save_"$nom".tgz /home/Agnes/a_sa
    # Copy the compressed file to the remote machine's /home/saves directory
   # scp /home/saves/save_"$nom".tgz asoque25@10.30.48.100:/home/saves/

### FIN DE LA SOUVEGARDE DES FICHIERS UTILISATEURS 

#INSTALLATION DE ECLIPSE
#apt install wgetJ_aimeRENNES&ISEN
#wget https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2021-09/R/eclipse-java-2021-09-R-linux-gtk-x86_64.tar.gz -O eclipse.tar.gz
#tar -xf eclipse.tar.gz
#mv eclipse /home
#chmod 775 /home/eclipse
#rm eclipse.tar.gz



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

