# Fase 1 — Instalación de Ubuntu Server 24.04.5 LTS (guía de la consola)

> La consola `vmconnect` ya está abierta con la VM `srv-universidad` encendida.
> Valores ya definidos y verificados en el host: **no los cambies**.

## Valores fijos del laboratorio

| Parámetro | Valor |
|---|---|
| Nombre del servidor (hostname) | `srv-universidad` |
| Interfaz de red | la que detecte el instalador (normalmente `eth0`) |
| IPv4 (manual) | `192.168.150.10/24` |
| Puerta de enlace | `192.168.150.1` |
| DNS | `8.8.8.8`, `1.1.1.1` |
| Disco | 20 GB (`/dev/sda` o `/dev/vda`) |

## Pasos en el instalador (subiquity)

1. **Idioma**: English (recomendado para que los mensajes coincidan con las guías) o Español.
2. **Installer update**: `Continue without updating` (evita depender de la red en este punto).
3. **Keyboard**: `Spanish` → `Spanish (Latin American)`.
4. **Type of install**: `Ubuntu Server` (NO la versión minimizada).
5. **Network**: selecciona la interfaz → `Edit IPv4` → `Manual`:
   - Subnet: `192.168.150.0/24`
   - Address: `192.168.150.10`
   - Gateway: `192.168.150.1`
   - Name servers: `8.8.8.8,1.1.1.1`
   - Search domains: dejar vacío
6. **Proxy**: dejar vacío → Continue.
7. **Mirror**: dejar el propuesto (`http://archive.ubuntu.com/ubuntu`). Si falla, usar
   `http://es.archive.ubuntu.com/ubuntu`.
8. **Storage**: `Use an entire disk` con el disco de 20 GB.
   - Recomendado: **desmarcar** "Set up this disk as an LVM group" (un solo ext4 es más
     fácil de explicar en el informe y de medir con `df -h`).
9. **Profile**:
   - Your name: `Administrador Web`
   - Server name: **`srv-universidad`**
   - Username: **`srvadmin`**
   - Password: la que elijas (anótala; se usará en la Fase 2 para SSH)
10. **Ubuntu Pro**: `Skip for now`.
11. **SSH setup**: marcar **`Install OpenSSH server`**.
    Dejar marcado `Allow password authentication over SSH`.
12. **Featured server snaps**: ninguno (Enter para continuar).
13. **Installing system** → esperar → `Reboot Now`.
14. Cuando pida `Please remove the installation medium, then press ENTER`: pulsa **Enter**
    (la ISO se expulsa sola del DVD virtual).

## Verificación tras el primer arranque (login con `srvadmin`)

```bash
hostname                          # debe devolver srv-universidad
ip -4 addr show                   # debe mostrar 192.168.150.10/24
ip route                          # default via 192.168.150.1
ping -c 3 8.8.8.8                 # salida a Internet a través del NAT
ping -c 3 archive.ubuntu.com      # resolución DNS
systemctl is-enabled ssh          # enabled
systemctl is-active ssh           # active
df -h /                           # ~20 GB en /
```

## Capturas de pantalla a tomar (evidencias del informe)

1. Pantalla de selección de red/IP manual del instalador.
2. Pantalla de perfil con el nombre `srv-universidad`.
3. Pantalla de SSH con `Install OpenSSH server` marcado.
4. Progreso/fin de instalación.
5. Primer login mostrando el banner de Ubuntu con la IP.
6. Salida de `hostname` + `ip -4 addr show` en el servidor ya instalado.
