#!/bin/bash

# -e: Finaliza el script cuando hay un error
# -x: Muestra el comando por pantalla
set -ex

# Actualiza los repositorios
sudo apt update

# Actualizamos los paquetes 
sudo apt upgrade -y

# Instalamos el servidor web Apache
sudo apt install -y apache2

# Instalamos PHP y módulo de MySQL
sudo apt install -y php libapache2-mod-php php-mysql

# Copiamos el archivo de configuración de Apache
sudo cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf

# Habilitamos el módulo rewrite de Apache
sudo a2enmod rewrite

# Reiniciar el servicio de Apache
sudo systemctl restart apache2

# Modificamos el propietario y el grupo de /var/www/html
sudo chown -R www-data:www-data /var/www/html
