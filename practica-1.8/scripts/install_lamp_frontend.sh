#!/bin/bash

#-e:Finaliza el script cuando hay un error
#-x: Muestra el comando por pantalla
set -x

#Actualiza los repositorios
apt update

#Actualizamos los paquetes 
apt upgrade -y

#Instalamos el servidor web apache
apt install apache2 -y

#Instalamos PHP
apt install php libapache2-mod-php php-mysql -y

#Copiamos el archivo de configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf

#Habilitamos el módulo rewrite de Apache
a2enmod rewrite

#Reiniciar el servicio de Apache
systemctl restart apache2

#Modificamos el propietario y el grupo de /var/www/html
chown -R www-data:www-data /var/www/html
