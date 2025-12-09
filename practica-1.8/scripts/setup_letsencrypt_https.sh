#!/bin/bash
set -ex

#importamos el archivo .env
source .env

#copiamos la plantilla del archivo VirtualHost en el servidor
cp ../conf/000-default.conf /etc/apache2/sites-available


#configuramos el Servername en el VirtualHost, buscamos PUT_YOUR_CERTBOT_DOMAIN_HERE y reemplazar por $CERTBOT_DOMAIN
sed -i "s/PUT_YOUR_CERTBOT_DOMAIN_HERE/$CERTBOT_DOMAIN/" /etc/apache2/sites-available/000-default.conf


#Instalamos snap
snap install core
snap refresh core


#Eliminamos
apt remove certbot -y

#Instalamos cerbot

snap install --classic certbot


#solicitamos el certificado a Let's Encrypt

certbot --apache -m "$CERTBOT_EMAIL" --agree-tos --no-eff-email -d "$CERTBOT_DOMAIN" --non-interactive
