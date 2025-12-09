# Práctica 1.8

##  Despliegue de una Arquitectura Web LAMP en Dos Niveles (Frontend + Backend)
En esta práctica se automatiza la instalación y configuración de una aplicación web LAMP repartida en dos instancias EC2 de AWS con Ubuntu Server:

- Capa Frontend: Servidor Apache + PHP que aloja WordPress. Es la única máquina accesible desde Internet.
- Capa Backend: Servidor MySQL. Solo acepta conexiones desde la red privada (VPC), concretamente desde el servidor Frontend. 

## Arquitectura de la solución
![Imagen](img/1.png)

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

![Imagen](img/4.png)

Ambas deben estar en la misma VPC y subred privada para que puedan comunicarse por sus IPs privadas.

**Grupos de seguridad**
- FRONTEND: debe permitir tráfico web desde cualquier parte del mundo y SSH solo desde tu IP.

![Imagen](img/2.png)

- BACKEND: solo tú por SSH y el FRONTEND por MySQL.

![Imagen](img/3.png)

Para facilitar la configuración, al principio puedes poner 0.0.0.0/0 en el puerto 3306, probar, y luego restringirlo a la IP privada del FRONTEND.

## Instalación Paso a Paso

### PASO 1 Configuración del entorno: archivo .env
Crea la carpeta conf/ en el proyecto y el archivo 000-default.conf con este contenido:

```
<VirtualHost *:80>
#ServerName www.example.com
ServerAdmin webmaster@localhost
DocumentRoot /var/www/html/


DirectoryIndex index.php index.html


ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

### PASO 2
Entramos en la carpeta de scripts:

```
cd ~/practica-1.5/scripts 
```

### PASO 3
Creamos el archivo .env con tus datos reales:

```
CERTBOT_EMAIL=test@iescelia.org
CERTBOT_DOMAIN=dawtest.ddns.net
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
Creeamos el fichero setup_letsencrypt_certificate.sh dentro del directorio scripts. Con el siguiente contenido:

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
### PASO 6
Ejecutamos el srcipt de Cerbot:

```
sudo ./setup_letsencrypt_certificate.sh
```
En el caso de ser necesario antes de ejecutarlo procede a dar permisos:

```
chmod +x setup_letsencrypt_certificate.sh
```
### PASO 7
Durante la ejecución del comando anterior tendremos que contestar algunas preguntas:

- Habrá que introducir una dirección de correo electrónico. (Ejemplo: demo@demo.es)
- Aceptar los términos de uso. (Ejemplo: y)
- Nos preguntará si queremos compartir nuestra dirección de correo electrónico con la Electronic Frontier Foundation. (Ejemplo: n)
- Y finalmente nos preguntará el nombre del dominio, si no lo encuentra en los archivos de configuración del servidor web. (Ejemplo: practicahttps.ml)

Si todo esta correcto la terminal se mostrara como en la imagen.

![Imagen](img/1.png)

### PASO 8
Mostramos todos los temporizadores activos del sistema, incluyendo su nombre, el servicio que activan, la fecha y hora de la próxima ejecución, el tiempo que queda hasta esa ejecución y el estado del temporizador:

```
systemctl list-timers
```
![Imagen](img/3.png)

### PASO 9
Una vez llegado hasta este punto tendríamos nuestro sitio web con HTTPS habilitado y todo configurado para que el certificado se vaya renovando automáticamente. Y se mostrara en nuestra web el candado como en la siguiente imagen:

![Imagen](img/2.png)
![Imagen](img/4.png)



##### María del Mar López Montoya | 2ºDAW

