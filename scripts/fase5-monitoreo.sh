#!/usr/bin/env bash
# Fase 5 - Supervision del servidor: CPU, memoria, disco, servicio y logs
# Uso: sudo bash /tmp/scripts/fase5-monitoreo.sh

set -uo pipefail
WWW="/var/www/universidad"

sec() { printf '\n\033[1;34m===== %s =====\033[0m\n' "$1"; }

sec "Identificacion del servidor"
hostname
uname -r
uptime

sec "Procesadores y carga"
nproc
lscpu | grep -E 'Nombre del modelo|Model name|^CPU\(s\)|Velocidad|MHz' | head -6

sec "Procesos con mayor consumo (top -bn1)"
top -bn1 | head -n 15

sec "Memoria RAM y swap"
free -h

sec "Espacio en disco"
df -hT

sec "Uso del contenido web"
du -sh "$WWW"
du -ah "$WWW" | sort -h | tail -n 5

sec "Estado del servicio Nginx"
systemctl status nginx --no-pager -l | head -n 15

sec "Puerto 80 en escucha"
ss -ltnp '( sport = :80 )'

sec "Ultimos eventos del servicio (journalctl)"
journalctl -u nginx -n 10 --no-pager

sec "Ultimos accesos registrados"
tail -n 10 /var/log/nginx/universidad.access.log 2>/dev/null || echo "sin registros aun"

sec "Ultimos errores registrados"
tail -n 10 /var/log/nginx/universidad.error.log 2>/dev/null || echo "sin registros aun"

printf '\n\033[1;32mFase 5 completada.\033[0m\n'
