#!/bin/bash

# -e: Finaliza el script cuando hay un error
# -x: Muestra cada comando que se ejecuta
set -ex

# Actualiza los repositorios
sudo apt update

# Actualizamos los paquetes
sudo apt upgrade -y

# Instalamos MySQL Server
sudo apt install -y mysql-server

echo "[BACKEND] Haciendo copia de seguridad de mysqld.cnf..."
sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak

echo "[BACKEND] Configurando bind-address para aceptar conexiones remotas..."
# Cambiamos la línea bind-address para que escuche en todas las interfaces
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "[BACKEND] Reiniciando MySQL..."
sudo systemctl restart mysql

echo "[BACKEND] MySQL instalado y escuchando conexiones remotas."
