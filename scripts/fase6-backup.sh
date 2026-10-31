#!/usr/bin/env bash
# Fase 6 - Copia de seguridad y prueba de restauracion
# Uso: sudo bash /tmp/scripts/fase6-backup.sh

set -euo pipefail

ORIGEN="/var/www/universidad"
DESTINO="/var/backups/universidad"
FECHA="$(date +%Y%m%d-%H%M%S)"
ARCHIVO="$DESTINO/universidad-$FECHA.tar.gz"

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

[[ $EUID -eq 0 ]] || { echo "ERROR: ejecuta con sudo." >&2; exit 1; }

paso "1. Preparando el directorio de copias"
mkdir -p "$DESTINO"
chmod 750 "$DESTINO"
echo "   $DESTINO"

paso "2. Creando la copia comprimida"
tar -czf "$ARCHIVO" -C /var/www universidad
ls -lh "$ARCHIVO"

paso "3. Calculando y guardando la huella SHA-256"
sha256sum "$ARCHIVO" | tee "$ARCHIVO.sha256"

paso "4. Verificando integridad del archivo"
sha256sum -c "$ARCHIVO.sha256"

paso "5. Contenido del backup"
tar -tzf "$ARCHIVO"

paso "6. Simulacion de perdida: eliminando index.html"
rm -f "$ORIGEN/index.html"
ls -l "$ORIGEN"
curl -s -o /dev/null -w "   peticion con el sitio roto -> HTTP %{http_code}\n" http://127.0.0.1/

paso "7. Restauracion desde la copia"
rm -rf /tmp/restauracion
mkdir -p /tmp/restauracion
tar -xzf "$ARCHIVO" -C /tmp/restauracion
install -m 0664 -o root -g webadmin "/tmp/restauracion/universidad/index.html" "$ORIGEN/index.html"
ls -l "$ORIGEN"

paso "8. Verificacion de la restauracion"
curl -s -o /dev/null -w "   peticion con el sitio restaurado -> HTTP %{http_code} | %{size_download} bytes\n" http://127.0.0.1/
sha256sum "$ORIGEN/index.html" "/tmp/restauracion/universidad/index.html"

paso "9. Copias disponibles"
ls -lh "$DESTINO"

printf '\n\033[1;32mFase 6 completada.\033[0m\n'
