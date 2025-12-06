#!/bin/bash
# Script para crear la BD de WordPress y el usuario en MySQL

set -e  # si algo falla, el script se para

# Cargamos las variables del .env (DB_NAME, DB_USER, DB_PASS, IP_MAQUINA_CLIENTE)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

echo "[BACKEND] Creando base de datos y usuario de MySQL para WordPress..."
echo "  DB_NAME: $DB_NAME"
echo "  DB_USER: $DB_USER"
echo "  IP cliente permitido: $IP_MAQUINA_CLIENTE"

# Ejecutamos el bloque SQL que pide el enunciado
mysql -u root <<EOF
DROP USER IF EXISTS '$DB_USER'@'$IP_MAQUINA_CLIENTE';
CREATE USER '$DB_USER'@'$IP_MAQUINA_CLIENTE' IDENTIFIED BY '$DB_PASS';
CREATE DATABASE IF NOT EXISTS $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$IP_MAQUINA_CLIENTE';
FLUSH PRIVILEGES;
EOF

echo "[BACKEND] Usuario y base de datos configurados correctamente."
