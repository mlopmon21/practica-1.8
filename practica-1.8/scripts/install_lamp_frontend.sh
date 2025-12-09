#!/bin/bash
#-e Finaliza el script cuando hay error, -x muestra el comando por pantalla
set -ex 
#Actualiza los repositorios
apt update
#Actualizamos los paquetes , se pone la y para que la pregunta yes la responda automáticamica a yes
apt upgrade -y

#Instalamos servidor web Apache
sudo apt install apache2 -y

# Habilitamos el modulo rewrite de Apache
a2enmod rewrite

#Instalamos PhP
sudo apt install php libapache2-mod-php php-mysql -y

#Copiamos el archivo de configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available

#Reiniciamos el servicio Apache
sudo systemctl restart apache2

#Copiamos nuestro archivo de prueba Php a /var/www/html

cp ../php/index.php /var/www/html

#Modificamos el propietario del directorio /var/www/html
chown -R www-data:www-data /var/www/html