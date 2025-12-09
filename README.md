# Práctica 1.8

##  Despliegue de una Arquitectura Web LAMP en Dos Niveles (Frontend + Backend)
En esta práctica se automatiza la instalación y configuración de una aplicación web LAMP repartida en dos instancias EC2 de AWS con Ubuntu Server:

- Capa Frontend: Servidor Apache + PHP que aloja WordPress. Es la única máquina accesible desde Internet.
- Capa Backend: Servidor MySQL. Solo acepta conexiones desde la red privada (VPC), concretamente desde el servidor Frontend. 

## Arquitectura de la solución
![Prueba](/practica-1.8/img/1.png)

## Estructura del repositorio
```
practica-1.8/
├── conf/
│   └── 000-default.conf                # VirtualHost de Apache (FRONTEND)
├── htaccess/
│   └── .htaccess                       # Reglas de reescritura (WordPress / pruebas)
├── php/
│   └── index.php                       # Script PHP de prueba
├── scripts/
│   ├── .env                            # Variables de entorno
│   ├── deploy_backend.sh               # Crea BD y usuario en BACKEND
│   ├── deploy_frontend.sh              # Despliega WordPress en FRONTEND
│   ├── install_lamp_backend.sh         # Instala y configura MySQL en BACKEND
│   ├── install_lamp_frontend.sh        # Instala Apache + PHP en FRONTEND
│   └── setup_letsencrypt_https.sh      # HTTPS con Let’s Encrypt
└── README.md                           # Documento técnico (este archivo)

```
## Requisitos Previos
- Un sistema operativo Linux (en este caso Ubuntu).
- Acceso a internet para descargar paquetes.
- Un usuario con permisos de sudo ambas máquinas.
- Dos instancias EC2 Ubuntu Server 24.04 LTS.
- Ambas en la misma VPC y Subred.
- Un par de claves (key pair) para acceder por SSH.
- Puertos abiertos en los grupos de seguridad según se indica más abajo.
- DNS apuntando a la IP pública del FRONTEND (si vas a usar Let’s Encrypt / dominio propio).

## Configuración de AWS creación de las instancias

**Instancia FRONTEND**
- Ubuntu Server 24.04
- IP pública (Asignamos direccion IP elásticas, para mantener IP pública fija al reiniciar la instancia).

**Instancia BACKEND**
- Ubuntu Server 24.04
- IP privada (no es necesario exponer IP pública).

![Prueba](/practica-1.8/img/4.png)

Ambas deben estar en la misma VPC y subred privada para que puedan comunicarse por sus IPs privadas.

**Grupos de seguridad**
- FRONTEND: debe permitir tráfico web desde cualquier parte del mundo y SSH solo desde tu IP.

![Prueba](/practica-1.8/img/2.png)

- BACKEND: solo tú por SSH y el FRONTEND por MySQL.

![Prueba](/practica-1.8/img/3.png)

Para facilitar la configuración, al principio puedes poner 0.0.0.0/0 en el puerto 3306, probar, y luego restringirlo a la IP privada del FRONTEND.

## Instalación Paso a Paso

### PASO 1 Configurar conf/000-default.conf
En la carpeta conf/ tenemos el archivo de VirtualHost de Apache:

conf/000-default.conf

Contenido:

```
<VirtualHost *:80>
    #ServerName PUT_YOUR_CERTBOT_DOMAIN_HERE
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/

    DirectoryIndex index.php index.html

    <Directory /var/www/html>
        AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
Puntos clave:

DocumentRoot /var/www/html → aquí irá WordPress.

El bloque <Directory> permite que .htaccess funcione (AllowOverride All).

Más adelante, el script install_lamp_frontend.sh copiará este archivo a:

```
/etc/apache2/sites-available/000-default.conf

```

### PASO 2 Configurar htaccess/.htaccess
El archivo htaccess/.htaccess contiene las reglas de reescritura para URLs amigables de WordPress:

```
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule> 
```

### PASO 3 Preparar la carpeta scripts y el archivo .env
En scripts/ tenemos los scripts de instalación y el archivo .env.

### Archivo: scripts/.env

```
# ============================
# CONFIGURACIÓN HTTPS (LETSENCRYPT EN MI FRONTEND)
# ============================

# Este es el correo que voy a usar para que Certbot me envíe avisos importantes
CERTBOT_EMAIL=test@iescelia.org

# Este es el dominio (o subdominio) que tengo apuntando a la IP pública de mi FRONTEND
CERTBOT_DOMAIN=dawtest.ddns.net


# ============================
# CONFIGURACIÓN DE MI BASE DE DATOS (BACKEND)
# ============================

# Nombre de la base de datos que voy a usar para WordPress
DB_NAME=wordpress

# Usuario de MySQL que voy a crear para que WordPress se conecte
DB_USER=db_user

# Contraseña del usuario de MySQL anterior
DB_PASSWORD=db_password

# Nombre DNS interno de mi máquina FRONTEND dentro de la VPC.
# Si en mis scripts uso esta variable para crear el usuario en MySQL,
# este será el "host" desde el que permito que se conecte.
IP_MAQUINA_CLIENTE=ip-172-31-26-110.ec2.internal

# IP PRIVADA de mi servidor BACKEND (donde está MySQL).
# Esta IP es la que WordPress usará como DB_HOST en wp-config.php.
DB_HOST=172.31.22.171


# ============================
# CONFIGURACIÓN DE MI WORDPRESS
# ============================

# Título que le voy a poner a mi sitio WordPress
WORDPRESS_TITLE="Sitio de DAW"

# Usuario administrador que voy a usar para entrar en WordPress
WORDPRESS_ADMIN_USER=admin

# Contraseña del usuario administrador de WordPress
WORDPRESS_ADMIN_PASSWORD=password

# Correo del administrador de WordPress (el mío)
WORDPRESS_ADMIN_EMAIL=admin@iescelia.org


# ============================
# SEGURIDAD Y OTRAS VARIABLES
# ============================

# Ruta "secreta" que voy a usar para acceder al login de WordPress
# (por ejemplo: http://MI_DOMINIO/secreto)
URL_HIDE_LOGIN=secreto

# IP PRIVADA de mi BACKEND, que usaré como ayuda en algunos scripts
# (por ejemplo para configurar el bind-address de MySQL)
BACKEND_PRIVATE_IP=172.31.22.171

```

### PASO 4 Configuración de la máquina BACKEND
Todo este paso se hace conectado por SSH a la instancia BACKEND.

### Ejecutar install_lamp_backend.sh
Este es el contenido de install_lamp_backend.sh:

```
#!/bin/bash
#-e Finaliza el script cuando hay error, -x muestra el comando por pantalla
set -ex 

# Cargamos las variables de entorno
source .env

#Actualiza los repositorios
apt update

#Actualizamos los paquetes , se pone la y para que la pregunta yes la responda automáticamica a yes
apt upgrade -y

#Instalamos servidor web Apache
sudo apt install apache2 -y

#Instalamos PhP
sudo apt install php libapache2-mod-php php-mysql -y

#Copiamos el archivo de configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available

#Reiniciamos el servicio Apache
sudo systemctl restart apache2

#Copiamos nuestro archivo de prueba Php a /var/www/html

cp ../php/index.php /var/www/html

# Instalamos mysql server
apt install mysql-server -y

# Configurar el parámetro bind-address
sudo sed -i "s/127.0.0.1/$BACKEND_PRIVATE_IP/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciamos MySQL para aplicar la configuración
systemctl restart mysql
```
Le damos permiso con el siguiente comando:

```
chmod +x install_lamp_backend.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./install_lamp_backend.sh
```

### Ejecutar deploy_backend.sh

Este es el contenido de deploy_backend.sh:

```
#!/bin/bash
set -ex

# Cargamos variables del .env
source .env

# Creamos la base de datos (solo si no existe)
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"

# Creamos el usuario para el FRONTEND y le damos permisos
mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'${IP_MAQUINA_CLIENTE}' IDENTIFIED BY '${DB_PASSWORD}';"

mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${IP_MAQUINA_CLIENTE}';"

mysql -u root -e "FLUSH PRIVILEGES;"
```
Le damos permiso con el siguiente comando:

```
chmod +x deploy_backend.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./deploy_backend.sh
```

### PASO 5 Configuración de la máquina FRONTEND
Todo este paso se hace conectado por SSH a la instancia FRONTEND.

### Ejecutar install_lamp_frontend.sh

Este es el contenido de install_lamp_frontend.sh:

```
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
```
Le damos permiso con el siguiente comando:

```
chmod +x install_lamp_frontend.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./install_lamp_frontend.sh
```

### PASO 6 Desplegar WordPress (deploy_frontend.sh)
Este es el contenido de deploy_frontend.sh:

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

# Creamos el archivo wp-config.php apuntando al BACKEND
# CORRECCIÓN: Usamos DB_PASS para coincidir con el estándar
wp config create \
  --dbname="$DB_NAME" \
  --dbuser="$DB_USER" \
  --dbpass="$DB_PASSWORD" \
  --dbhost="$DB_HOST" \
  --path=/var/www/html \
  --allow-root

# Instalamos WordPress
wp core install \
  --url="$CERTBOT_DOMAIN" \
  --title="$WORDPRESS_TITLE" \
  --admin_user="$WORDPRESS_ADMIN_USER" \
  --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
  --admin_email="$WORDPRESS_ADMIN_EMAIL" \
  --path=/var/www/html \
  --allow-root   

# Configuramos los enlaces permanentes
wp rewrite structure '/%postname%/' \
  --path=/var/www/html \
  --allow-root

# Instalamos el plugin de WPS Hide Login
wp plugin install wps-hide-login --activate \
    --path=/var/www/html \
    --allow-root

# Configuramos una URL personalizada para la página de login
wp option update whl_page "$URL_HIDE_LOGIN" --path=/var/www/html --allow-root

# Copiamos el archivo .htaccess a /var/www/html
cp ../htaccess/.htaccess /var/www/html/.htaccess

# Modificamos el propietario y el grupo de /var/www/html a www-data
chown -R www-data:www-data /var/www/html
```
Le damos permiso con el siguiente comando:

```
chmod +x deploy_frontend.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./deploy_frontend.sh
```
![Prueba](/practica-1.8/img/5.png)

### PASO 7 HTTPS con Let’s Encrypt (setup_letsencrypt_https.sh)
Este es el contenido de deploy_frontend.sh:

```
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

```
Le damos permiso con el siguiente comando:

```
chmod +x setup_letsencrypt_https.sh
```

Por último ejecutamos el script en la terminal:

```
sudo ./setup_letsencrypt_https.sh
```

![Prueba](/practica-1.8/img/6.png)

### Paso 8 Comprobar el login oculto de WordPress
![Imagen](/practica-1.8/img/7.png)

##### María del Mar López Montoya | 2ºDAW
