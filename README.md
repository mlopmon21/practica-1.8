# Práctica 1.8

## Arquitectura LAMP de dos niveles con WordPress en AWS (frontend + backend)

En esta guía se describe, paso a paso, cómo se automatiza la instalación y configuración de una aplicación web WordPress utilizando una arquitectura LAMP en dos niveles sobre dos instancias EC2 de Amazon Web Services (AWS):

- Una máquina BACKEND con MySQL Server.
- Una máquina FRONTEND con Apache + PHP + WordPress.

Toda la configuración se realiza mediante scripts de Bash y un archivo `.env` común, y se habilita HTTPS con Let’s Encrypt utilizando un dominio dinámico (`dawtest.ddns.net`) gestionado con No-IP.

## Estructura del repositorio
```
practica-1.8/
├── conf/
│   └── 000-default.conf                # Configuración del VirtualHost de Apache
├── htaccess/
│   └── .htaccess                       # Reglas de reescritura para WordPress
├── scripts/
│   ├── .env                            # Variables de entorno compartidas
│   ├── install_lamp_frontend.sh        # Instalación LAMP en la máquina frontend
│   ├── install_lamp_backend.sh         # Instalación LAMP (MySQL) en la máquina backend
│   ├── deploy_frontend.sh              # Despliegue de WordPress en la máquina frontend
│   ├── deploy_backend.sh               # Creación de BD y usuario en la máquina backend
│   └── setup_letsencrypt_https.sh      # Configuración de HTTPS con Let’s Encrypt
└── README.md                           # Documentación del proyecto
```
## Requisitos Previos
- Dos instancias EC2 con Ubuntu Server: Una para backend (MySQL) y otra para frontend (Apache + WordPress).
- Usuario con permisos sudo en ambas máquinas.
- Puertos abiertos en AWS / Security Group:
- Backend: 22 (SSH) y 3306 (MySQL) desde la subred apropiada.
- Frontend: 22 (SSH), 80 (HTTP), 443 (HTTPS).
- Cuenta en No-IP y host configurado (dawtest.ddns.net).
- El dominio dawtest.ddns.net debe apuntar a la IP pública de la máquina frontend.

## Instalación Paso a Paso

### PASO 1 Clonado del repositorio y flujo de trabajo con Git (dos máquinas)
En esta práctica se trabaja con un único repositorio GitHub y dos máquinas (frontend y backend).

En cada máquina (frontend y backend):

```
cd ~
git clone https://github.com/usuario/practica-1.8.git
cd practica-1.8/practica-1.8
```
A partir de ahora, todo se hace dentro de ~/practica-1.8/practica-1.8.

####

### PASO 2
Entramos en la carpeta de scripts:

```
cd ~/practica-1.6/scripts 
```

### PASO 3
Creamos el archivo .env. En esta práctica incluimos nuevas variables para configurar el usuario administrador de WordPress y la URL oculta de login.

```
CERTBOT_EMAIL=test@iescelia.org
CERTBOT_DOMAIN=dawtest.ddns.net

DB_NAME=wordpress
DB_USER=db_user
DB_PASSWORD=db_password
IP_CLIENTE_MYSQL=localhost
DB_HOST=localhost

WORDPRESS_TITLE="Sitio de DAW"
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=password
WORDPRESS_ADMIN_EMAIL=admin@iescelia.org

# URL personalizada para ocultar el login (ej: midominio.com/secreto)
URL_HIDE_LOGIN=secreto
```

### PASO 4
Copiamos el script install_lamp.sh del proyecto anterior.
Por si no lo tienes son los siguientes comandos: 

```
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

# Instalamos mysql server
apt install mysql-server -y

```
Le damos permiso con el siguiente comando:

```
chmod +x install_lamp.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./install_lamp.sh
```
### PASO 5
Despliegue de WordPress con WP-CLI. Este script es diferente al método tradicional. Descarga la herramienta wp-cli, instala WordPress desde la consola, configura la base de datos, activa los enlaces permanentes y, lo más importante, instala y configura el plugin WPS Hide Login.

Contenido de deploy.sh:

```
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
```

Le damos permiso con el siguiente comando:

```
chmod +x deploy.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./deploy.sh
```
### PASO 6
Configuración de HTTPS. Usamos el script setup_letsencrypt_certificate.sh para solicitar el certificado SSL a Let's Encrypt utilizando Certbot.

Contenido de setup_letsencrypt_certificate.sh:

```
#!/bin/bash
set -ex

#Importamos el archivo .env
source .env

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
```

Le damos permiso con el siguiente comando:

```
chmod +x setup_letsencrypt_certificate.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./setup_letsencrypt_certificate.sh
```
![Imagen](img/1.png)

### PASO 7
Verificación. Ahora accedemos a nuestro dominio. IMPORTANTE: Como hemos instalado el plugin de seguridad, ya no podremos acceder por /wp-admin. Ahora debemos usar la ruta que definimos en la variable URL_HIDE_LOGIN del archivo .env.

Ejemplo: https://dawtest.ddns.net/secreto

![Imagen](img/2.png)




##### María del Mar López Montoya | 2ºDAW


