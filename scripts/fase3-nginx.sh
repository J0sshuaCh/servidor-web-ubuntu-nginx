#!/usr/bin/env bash
# Fase 3 - Instalacion y configuracion de Nginx para el sitio universitario
# Uso: sudo bash /tmp/fase3-nginx.sh
# Requiere: /tmp/sitio/index.html, /tmp/sitio/estilos.css, /tmp/sitio/favicon.svg

set -euo pipefail

WWW="/var/www/universidad"
SITIO="universidad"
ORIGEN="/tmp/sitio"

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: ejecuta este script con sudo." >&2
  exit 1
fi

if [[ ! -f "$ORIGEN/index.html" ]]; then
  echo "ERROR: no se encuentra $ORIGEN/index.html. Copia primero la carpeta 'sitio' a /tmp." >&2
  exit 1
fi

paso "1. Actualizando indices de paquetes"
apt-get update -qq

paso "2. Instalando Nginx"
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx >/dev/null
dpkg-query -W -f='   nginx instalado: ${Version}\n' nginx

paso "3. Publicando contenido en $WWW"
mkdir -p "$WWW"
install -m 0644 "$ORIGEN/index.html"  "$WWW/index.html"
install -m 0644 "$ORIGEN/estilos.css" "$WWW/estilos.css"
install -m 0644 "$ORIGEN/favicon.svg" "$WWW/favicon.svg"
chown -R root:www-data "$WWW"
find "$WWW" -type d -exec chmod 0755 {} +
find "$WWW" -type f -exec chmod 0644 {} +
ls -l "$WWW"

paso "4. Escribiendo el sitio virtual /etc/nginx/sites-available/$SITIO"
cat > "/etc/nginx/sites-available/$SITIO" <<'CONF'
server {
    listen 80;
    listen [::]:80;

    server_name srv-universidad universidad.local www.universidad.local;

    root /var/www/universidad;
    index index.html;

    access_log /var/log/nginx/universidad.access.log;
    error_log  /var/log/nginx/universidad.error.log;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(css|js|svg|png|jpe?g|ico|woff2?)$ {
        expires 7d;
        access_log off;
    }

    location = /favicon.ico {
        alias /var/www/universidad/favicon.svg;
        access_log off;
    }
}
CONF

paso "5. Habilitando el sitio y desactivando el predeterminado"
ln -sfn "/etc/nginx/sites-available/$SITIO" "/etc/nginx/sites-enabled/$SITIO"
rm -f /etc/nginx/sites-enabled/default
nginx -T >/dev/null 2>&1 || true

paso "6. Validando la configuracion (nginx -t)"
nginx -t

paso "7. Habilitando y recargando el servicio"
systemctl enable nginx >/dev/null 2>&1
systemctl reload nginx || systemctl restart nginx

paso "8. Verificaciones"
echo "-- Estado del servicio --"
systemctl is-enabled nginx
systemctl is-active nginx
echo
echo "-- Puerto 80 en escucha --"
ss -ltnp '( sport = :80 )' | tail -n +1
echo
echo "-- Respuesta local --"
curl -s -o /dev/null -w "   HTTP %{http_code} | %{size_download} bytes | %{content_type}\n" http://127.0.0.1/
echo
echo "-- Archivos publicados --"
ls -la "$WWW"

printf '\n\033[1;32mFase 3 completada.\033[0m Sitio disponible en http://192.168.150.10/\n'
