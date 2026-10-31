#!/usr/bin/env bash
# Fase 7 - Resumen consolidado de evidencias del servidor
# Uso: sudo bash /tmp/scripts/fase7-evidencias.sh
set -uo pipefail
sep() { printf '%s\n' "--------------------------------------------------------------"; }

echo "EVIDENCIAS DE IMPLEMENTACION - SERVIDOR WEB"
echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')  |  Host: $(hostname)"
sep
echo "[1] SISTEMA OPERATIVO"
hostnamectl | grep -E 'Static hostname|Operating System|Kernel|Virtualization'
sep
echo "[2] RED"
ip -4 -br addr show eth0
ip route | head -n 2
sep
echo "[3] NGINX"
nginx -v 2>&1
echo -n "habilitado: "; systemctl is-enabled nginx
echo -n "estado:     "; systemctl is-active nginx
nginx -t 2>&1 | tail -n 1
ss -ltn '( sport = :80 )' | tail -n 1
sep
echo "[4] CONTENIDO PUBLICADO"
ls -l /var/www/universidad
sep
echo "[5] USUARIOS Y PERMISOS"
id adminweb
getent group webadmin
ls -ld /var/www/universidad
sep
echo "[6] RECURSOS"
free -h | head -n 2
df -h / | tail -n 1
sep
echo "[7] DISPONIBILIDAD DEL SITIO"
curl -s -o /dev/null -w 'GET /      -> HTTP %{http_code} (%{size_download} bytes)\n' http://127.0.0.1/
curl -s -o /dev/null -w 'GET /no-existe -> HTTP %{http_code}\n' http://127.0.0.1/no-existe
sep
echo "[8] COPIAS DE SEGURIDAD"
ls -lh /var/backups/universidad | tail -n 3
sep
echo "[9] ULTIMOS ACCESOS REGISTRADOS"
tail -n 5 /var/log/nginx/universidad.access.log
sep
echo "FIN DE LAS EVIDENCIAS"
