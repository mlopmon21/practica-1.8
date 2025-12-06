#!/bin/bash

#-e:Finaliza el script cuando hay un error
#-x: Muestra el comando por pantalla
set -x

#Actualiza los repositorios
apt update

#Actualizamos los paquetes 
apt upgrade -y


#Instalamos MySQL Server
apt install mysql-server -y

#Actualiza el parametro bind-address para que acepte conexiones remotas
cp /etc/mysql/mysql.conf.d/mysqld.cnf