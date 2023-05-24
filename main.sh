#!/bin/bash


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
	ssh -n -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "mail --subject \"Creation de compte $nom \" --exec \"set sendmail=smtp://antonin.soquet%40isen-ouest.yncrea.fr:J_aimeRENNES&ISEN@smtp.office365.com:587\" --append \"From:antonin.soquet@isen-ouest.yncrea.fr\" antonsoquet@gmail.com <<<\"Bonjour $nom $prenom, \\n Voici vos informations de connexion : &\n&\n Nom d'utilisateur : $login  \n Mot de passe : $motdepasse &\n&\n Veuillez changer votre mot de passe lors de votre premiere connexion.\" "	
#done < accounts.csv
done < <(tail -n +2 accounts.csv)

### MISE EN PLACE DE LA SOUVEGARDE DES FICHIERS DES UTILISATEURS SUR LE SERVEUR

# Compress the contents of a_sauver directory to .tgz format
# nom = "Agnes"  
#  tar -czf /home/Agnes/save_"$nom".tgz /home/Agnes/a_sa
    # Copy the compressed file to the remote machine's /home/saves directory
   # scp /home/saves/save_"$nom".tgz asoque25@10.30.48.100:/home/saves/

### FIN DE LA SOUVEGARDE DES FICHIERS UTILISATEURS 


### MISE EN PLACE DE L'ENVOIE DU MAIL

sudo apt-get upgrade ssmtp


#read -p "Enter your e-mail: " loginMail
#read -p "Enter your Password: " pwdMail


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

