#!/bin/bash
# setup_ssh.sh

SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"
CONFIG_SOURCE="ssh_config_per_connectar.txt"

echo "🎯 Iniciando configuración local de ProxyJump..."

if [ ! -d "$SSH_DIR" ]; then
    echo "   Creando el directorio $SSH_DIR..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

echo "   Moviendo claves .pem a $SSH_DIR/ y asignando permisos 400..."
find . -maxdepth 1 -name "*.pem" -print0 | while IFS= read -r -d $'\0' file; do
    echo "      -> $file"
    mv "$file" "$SSH_DIR/"
    chmod 400 "$SSH_DIR/$(basename "$file")"
done

if [ -f "$CONFIG_SOURCE" ]; then
    echo "   Procesando configuración SSH desde $CONFIG_SOURCE..."

    if grep -q "# START: Configuració Terraform ProxyJump" "$CONFIG_FILE" 2> /dev/null; then
        echo "      -> Eliminando configuración anterior..."
        awk '/# START: Configuració Terraform ProxyJump/{flag=1} flag==0{print} /# END: Configuració Terraform ProxyJump/{flag=0}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    fi
    
    cat "$CONFIG_SOURCE" >> "$CONFIG_FILE"
    
    echo "   ✅ Configuración ProxyJump añadida a $CONFIG_FILE."
    echo ""
    echo "🚀 Conexión lista. Usa 'ssh bastion' o 'ssh private-1', etc."
else
    echo "   ❌ ERROR: No se encontró el archivo $CONFIG_SOURCE."
fi