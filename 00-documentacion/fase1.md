# Fase 1 — Máquina virtual e instalación de Ubuntu Server

## 1. Entorno

| Elemento | Valor |
|---|---|
| Hipervisor | Microsoft Hyper-V (Windows 11 Pro 26H2) |
| Equipo anfitrión | DESKTOP-2Q02MTB, MSI MS-7E64, 16 GB RAM |
| Imagen | `ubuntu-24.04.5-live-server-amd64.iso` (3,80 GB) |
| Integridad de la ISO | SHA-256 `97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8` (coincide con el oficial) |

## 2. Requisitos de hardware de la VM

| Recurso | Configuración aplicada |
|---|---|
| Generación | 2 (UEFI) |
| vCPU | 2 |
| Memoria | 4096 MB estáticos |
| Disco | VHDX de 20 GB (crecimiento dinámico) |
| Red | Conmutador interno `srv-lab` |
| Firmware | Secure Boot desactivado |

## 3. Red del laboratorio

Se crea un conmutador **interno** con NAT para aislar el servidor de la red real del
anfitrión (192.168.100.0/24) y aun así permitirle salida a Internet.

| Elemento | Valor |
|---|---|
| Conmutador | `srv-lab` (Internal) |
| IP del anfitrión en el conmutador | `192.168.150.1/24` |
| NAT | `srv-lab-nat` → `192.168.150.0/24` |
| IP del servidor | `192.168.150.10/24` |
| Puerta de enlace | `192.168.150.1` |
| DNS | `8.8.8.8`, `1.1.1.1` |

### Configuración aplicada en el servidor (`/etc/netplan/01-netcfg.yaml`)

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.150.10/24]
      routes:
        - to: default
          via: 192.168.150.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

Se desactiva la gestión de red por `cloud-init` (`/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg`)
para que la configuración no se sobrescriba en el siguiente arranque.

## 4. Instalación de Ubuntu Server

Parámetros elegidos en el instalador (subiquity):

| Paso | Valor |
|---|---|
| Tipo de instalación | Ubuntu Server (completa) |
| Teclado | Spanish (Latin American) |
| Particionado | Disco completo con LVM |
| Nombre del servidor | `srv-universidad` |
| Usuario administrador | `srvadmin` |
| OpenSSH server | Instalado |
| Ubuntu Pro | Omitido |

## 5. Verificaciones realizadas

Ejecutadas en el servidor:

```bash
hostnamectl          # Static hostname: srv-universidad
lsblk                # sda 20G -> sda1 /boot, sda2 /boot/efi, sda3 LVM
df -h /              # /dev/mapper/ubuntu--vg-ubuntu--lv
free -h              # 3,8 GiB totales
```

Ejecutadas desde el anfitrión:

```
ping 192.168.150.10      -> 4 enviados, 4 recibidos, 0 % perdidos, TTL=64
Test-NetConnection :22   -> TcpTestSucceeded = True
ARP 192.168.150.10       -> 00-15-5D-00-E8-04 (MAC de la VM)
```

## 6. Resultado

| Requisito | Estado |
|---|---|
| Ubuntu Server instalado en VM | Cumplido |
| Hostname configurado | Cumplido |
| IP estática operativa | Cumplido |
| Salida a Internet vía NAT | Cumplido |
| Servicio SSH accesible | Cumplido |

## 7. Capturas requeridas para el informe

1. Configuración de red manual en el instalador.
2. Pantalla de perfil con el nombre `srv-universidad`.
3. Selección de `Install OpenSSH server`.
4. Fin de la instalación / primer arranque.
5. `hostnamectl` + `ip -4 addr show eth0` en el servidor.
6. `ping` y prueba de puerto 22 desde el anfitrión.
