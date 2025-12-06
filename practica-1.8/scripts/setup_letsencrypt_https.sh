#!/bin/bash
set -ex

# Cargamos las variables del .env (DB_NAME, DB_USER, DB_PASS, IP_MAQUINA_CLIENTE)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

#Copiamos plantilla del archivo virtual host en el server importante
sudo cp ../conf/000-default.conf /etc/apache2/sites-available

#Realizamos la instalación y actualización del snap
sudo snap install core
sudo snap refresh core

#Eliminamos instalaciones previas a cerbot
sudo apt remove certbot -y

#Instalamos certbot
sudo snap install --classic certbot

# Creamos una alias para el comando certbot.
sudo ln -fs /snap/bin/certbot /usr/bin/certbot

# Obtenemos el certificado y configuramos el servidor web Apache.
#sudo certbot --apache

#Solicitamos el certificado a Let´s Encrypt
certbot --apache -m $CERTBOT_EMAIL --agree-tos --no-eff-email -d $CERTBOT_DOMAIN --non-interactive