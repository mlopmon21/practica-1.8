#!/bin/bash

set -ex

# Importamos las variables de entorno
source .env

# Eliminamos descargas previas de WP-CLI
rm -f /tmp/wp-cli.phar

# Descargamos WP-CLI
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

# Le asignamos permisos de ejecución
chmod +x /tmp/wp-cli.phar

# Movemos wp-cli.phar a /usr/local/bin/wp
mv /tmp/wp-cli.phar /usr/local/bin/wp

# Eliminamos instalaciones previas de WordPress
rm -rf /var/www/html/*

# Descargamos WordPress en español en el directorio /var/www/html
wp core download --locale=es_ES --path=/var/www/html --allow-root

# Creamos una base de datos de wordpress
mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME"
mysql -u root -e "CREATE DATABASE $DB_NAME"

# Creamos un usuario/contraseña para la base de datos
mysql -u root -e "DROP USER IF EXISTS $DB_USER@'$IP_CLIENTE_MYSQL'"
mysql -u root -e "CREATE USER $DB_USER@'$IP_CLIENTE_MYSQL' IDENTIFIED BY '$DB_PASSWORD'"

# Le asignamos privilegios al usuario
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@'$IP_CLIENTE_MYSQL'"

# Creamos el archivo wp-config.php
wp config create \
  --dbname=$DB_NAME \
  --dbuser=$DB_USER \
  --dbpass=$DB_PASSWORD \
  --dbhost=$DB_HOST \
  --path=/var/www/html \
  --allow-root

# Instalamos WordPress
wp core install \
  --url=$CERTBOT_DOMAIN \
  --title="$WORDPRESS_TITLE" \
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASSWORD \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html \
  --allow-root  

# Configuramos los enlaces permanentes
wp rewrite structure '/%postname%/' \
 --path=/var/www/html \
 --allow-root

#Instalamos el plugin de WPS Hide Login
wp plugin install wps-hide-login --activate \
    --path=/var/www/html \
    --allow-root

# Configuramos una URL personalizada para la página de login
wp option update whl_page $URL_HIDE_LOGIN --path=/var/www/html --allow-root

#Copiamos el archivo .htaccess a var/www/html
cp ../htaccess/.htaccess /var/www/html/.htaccess

# Mofificamos el propietario y el grupo de /var/www/html a www-data
chown -R www-data:www-data /var/www/html