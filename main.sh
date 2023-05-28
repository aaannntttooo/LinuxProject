#!/bin/bash
###
#PROJET LINUX - ANTONIN SOQUET - CIR3
###


# RECUPERATION EN ENTREE DES VALEURS AFIN DE CONFIGURER LE SERVEUR D'ENVOIE ET LES INFOMATIONS DU MAIL
MAIL_SERVER=$1
MAIL_LOGIN=$2
MAIL_PWD=$3 
#remplace '@' par '%40' afin de pouvoir utiser l'adresse mail
MAIL_LOGINSED=$(echo "$MAIL_LOGIN" | sed 's/@/%40/g')


mkdir /home/shared

#Creation du dossier saves sur le server
ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "mkdir saves"


#CREATION D'UN FICHIER POUR LE CRON
file="tamponCron.txt"
touch $file
#Le fichier CRON est ajoute au fichier tampon
crontab -u isen -l > $file


#LECTURE DU .CSV AVEC AFFECTATION DE CHAQUE INFORMATION
while read -r line; do	
	IFS=';' read -r nom prenom mail motdepasse <<< "$line"	
	#Creation du login de l'user avec la premiere lettre de son prenom et son nom
 	login=${nom:0:1}"$prenom"
	login=$(echo "$login" | sed 's/ /_/g')
#	echo "$login"
	useradd -m "$login" --home /home/"$login" --shell /bin/bash
	 echo "$login:$motdepasse" | chpasswd
	#permet de rendre le mdp a ussage unique
	 chage -d 0 "$login"

	mkdir /home/"$login"/a_sauver # Creation du dossier 'a_sauver' par user.	
	mkdir /home/shared/"$login"  # Creation du dossier par user dans Shared
	sudo chown "$login"  /home/shared/"$login" ###Seul l'utilisateur dont son nom est le fichier peut modifier le dossier 
	sudo chmod 755 /home/shared/"$login"
	

	#tar -czf /home/"$login"/save_"$login".tgz /home/"$login"/a_sauver
	#scp -i /home/isen/.ssh/id_rsa /home/"$login"/save_"$login".tgz asoque25@10.30.48.100:~/saves
	#Ligne qui ajouter au fichier CRON les donnees pour zipper, souvegarder sur le serveur et suppr le zip original tous les jours de la semaine a 23h
	line="0 23 * * 1-5 isen tar -czf /home/"$login"/save_"$login".tgz /home/"$login"/a_sauver;scp -i /home/isen/.ssh/id_rsa /home/"$login"/save_"$login".tgz asoque25@10.30.48.100:~/saves;rm  /home/"$login"/save_"$login".tgz"
	#La ligne est affecte au fichier tampon
	echo "$line" >> $file

	# Preparation des donnees pour l'envoie du mail
	TO="$mail"
	SUBJECT="Creation de compte"
	BODY="Bonjour $nom $prenom, 
Voici vos informations de connexion : 
Nom d'utilisateur : $login   
Mot de passe :$motdepasse  
Veuillez changer votre mot de passe lors de votre premiere connexion."
	#Permet d'envoyer le mail a chaque user
        ssh -n -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "mail --subject \"$SUBJECT \" --exec \"set sendmail=smtp://$MAIL_LOGINSED:$MAIL_PWD@smtp.$MAIL_SERVER\" --append \"From:$MAIL_LOGIN\" \"$mail\" <<<\"$BODY\" "

#La lecture du fichier ne commence qu'a la seconde ligne
done < <(tail -n +2 accounts.csv)

#copie du fichier tampon dans le fichier du cron
crontab -u isen $file
rm "$file"


###PARTIE MONITORING / En partie fonctionnelle
	#creer un fichier tampon pour le cron
	file="tamponCron.txt"
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "touch $file"
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "crontab -u isen -l > $file"
	#Creer un fichier ressources.log afin d'y ajouter les valeurs de LOAD du CPU, RAM et Réseau
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "touch ressources.log"
	#Permet de recuperer la valeur du load CPU
        CPU_LOAD=$(ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "top -bn1 | grep \"Cpu(s)\" | awk \'{print $2 + $4}\'")
	#Permet de recuperer la valeur du  Load Memoire
	MEMORY_LOAD=$(ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "free | awk \'/Mem/ {print $3/$2 * 100}\'")
	#Recuperer la date du jour et l'heure
	current_date=$(date +"%Y-%m-%d")
	current_time=$(date +"%H:%M:%S")
	#ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100
	#Creer la ligne a jouter au cron afin d'ecrire sur le fichier toutes les minutes de chaque jour en semaine. 
	line="* * * * 1-5 echo \"$current_date $current_time CPU\: $CPU_LOAD%  Memory\: $MEMORY_LOAD%\" >> ressources.log "
	#Copie la ligne dans le fichier file, qui va remplacer le fichier cron, puis etre supprime
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 " echo \"$line\" >> $file"
	ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "crontab -u $file"
        ssh -i /home/isen/.ssh/id_rsa asoque25@10.30.48.100 "rm $file"



###INSTALLATION D' ECLIPSE
#Recuperation du fichier zim d'eclipse sur la page web 
apt install wget
wget https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2021-09/R/eclipse-java-2021-09-R-linux-gtk-x86_64.tar.gz -O eclipse.tar.gz
#Unzip du  fichier telecharge
tar -xf eclipse.tar.gz
#Eclispe est deplace dans le home et est  accessible a tous les users
mv eclipse /home
chmod 775 /home/eclipse
rm eclipse.tar.gz





###MIS EN PLACE PARE-FEU
#Rejet des INPUT, OUTPUT et FORWARD des ports 20 et 21 pour le TCP et du port UDP
iptables-legacy -t filter -A INPUT -p tcp --dport 20 -j DROP
iptables-legacy -t filter -A INPUT -p tcp --dport 21 -j DROP
iptables-legacy -t filter -A INPUT -p udp -j DROP

sudo iptables-legacy -t filter -A OUTPUT -p tcp --dport 20 -j DROP
sudo iptables-legacy -t filter -A OUTPUT -p tcp --dport 21 -j DROP
sudo iptables-legacy -t filter -A OUTPUT -p udp -j DROP

sudo iptables-legacy -t filter -A FORWARD -p tcp --dport 20 -j DROP
sudo iptables-legacy -t filter -A FORWARD -p tcp --dport 21 -j DROP
sudo iptables-legacy -t filter -A FORWARD -p udp -j DROP



### Implementation de NEXTCLOUD
#J'ai tenter de realiser l'implantation d'un server Nextcloud sur le server en l'implementant d'abord en local, je n'ai pas reussi a faire ce que je voulais, j'ai laissé quelques lignes de code tout de même
#telecharge Nextcloud et apache 2
#wget https://download.nextcloud.com/server/releases/latest.tar.bz2
#sudo apt get install apache2

#Unzip du dosser
#tar -xvf latest.tar.bz2

#Mise en place sur serveur Netxcloud
#sudo mv nextcloud /var/www/html/
#sudo chown -R www-data:www-data /var/www/html/nextcloud/
#sudo a2ensite nextcloud.conf
#sudo a2dissite 000-default.conf
#sudo service apache2 restart

