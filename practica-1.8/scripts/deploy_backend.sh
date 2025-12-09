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