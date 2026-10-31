#!/usr/bin/env bash
# Fase 4 - Usuario adicional, grupo de administracion y permisos minimos
# Uso: sudo bash /tmp/scripts/fase4-usuarios.sh

set -euo pipefail

WWW="/var/www/universidad"
GRUPO="webadmin"
USUARIO="adminweb"

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

[[ $EUID -eq 0 ]] || { echo "ERROR: ejecuta con sudo." >&2; exit 1; }

paso "1. Grupo de administracion del sitio ($GRUPO)"
if getent group "$GRUPO" >/dev/null; then
  echo "   el grupo $GRUPO ya existe"
else
  groupadd "$GRUPO"
  echo "   grupo $GRUPO creado"
fi

paso "2. Usuario adicional ($USUARIO)"
if id "$USUARIO" >/dev/null 2>&1; then
  echo "   el usuario $USUARIO ya existe"
else
  useradd -m -s /bin/bash -c "Administrador web" -G "$GRUPO" "$USUARIO"
  echo "   usuario $USUARIO creado con home y shell"
fi
usermod -aG "$GRUPO" "$USUARIO"

paso "3. umask 002 para que los archivos nuevos nazcan editables por el grupo"
grep -q '^umask 002' "/home/$USUARIO/.bashrc" || echo 'umask 002' >> "/home/$USUARIO/.bashrc"

paso "4. Permisos del sitio (sin 777)"
chown -R "root:$GRUPO" "$WWW"
find "$WWW" -type d -exec chmod 2775 {} +
find "$WWW" -type f -exec chmod 0664 {} +
echo "   directorios 2775 (setgid) y archivos 0664"

paso "5. Estado de usuarios y grupos"
id "$USUARIO"
getent group "$GRUPO"

paso "6. Permisos resultantes"
ls -ld "$WWW"
ls -l "$WWW"

paso "7. Prueba positiva: adminweb crea un archivo en el sitio"
sudo -u "$USUARIO" bash -c "echo 'Archivo de prueba de permisos' > $WWW/prueba-permisos.txt"
ls -l "$WWW/prueba-permisos.txt"

paso "8. Nginx puede leer el archivo nuevo"
curl -s -o /dev/null -w "   GET /prueba-permisos.txt -> HTTP %{http_code}\n" http://127.0.0.1/prueba-permisos.txt
sudo -u www-data test -r "$WWW/index.html" && echo "   www-data puede leer index.html"

paso "9. Prueba negativa: adminweb no puede escribir fuera del sitio"
if sudo -u "$USUARIO" bash -c "touch /etc/prueba-prohibida" 2>/dev/null; then
  echo "   FALLO: pudo escribir en /etc (revisar permisos)" >&2
  rm -f /etc/prueba-prohibida
else
  echo "   correcto: escritura en /etc denegada"
fi

paso "10. Limpieza de la prueba"
rm -f "$WWW/prueba-permisos.txt"

printf '\n\033[1;32mFase 4 completada.\033[0m Falta asignar contrasena: sudo passwd %s\n' "$USUARIO"
