# Fase 1 - Preflight de Hyper-V (requiere elevacion)
# Solo LEE el estado del sistema. No crea, modifica ni elimina nada.

$ErrorActionPreference = 'SilentlyContinue'
$log = 'C:\Users\I5\Documents\Proyectos Web\TareaTaller\00-documentacion\salida-f1-preflight.log'

Set-Content -Path $log -Value "=== PREFLIGHT HYPER-V - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

function Sec($title, $data) {
    Add-Content -Path $log -Value ""
    Add-Content -Path $log -Value "--- $title ---"
    Add-Content -Path $log -Value ($data | Out-String -Width 200).TrimEnd()
}

$isAdmin = (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Sec 'Contexto' "Usuario: $env:USERNAME | Elevado: $isAdmin | Host: $env:COMPUTERNAME"

Sec 'Caracteristicas de Windows' (Get-WindowsOptionalFeature -Online -FeatureName `
        Microsoft-Hyper-V-All, Microsoft-Hyper-V-Management-PowerShell, Microsoft-Hyper-V-Management-Clients |
    Select-Object FeatureName, State)

Sec 'Conmutadores virtuales' (Get-VMSwitch | Select-Object Name, SwitchType, NetAdapterInterfaceDescription)

Sec 'Maquinas virtuales existentes' (Get-VM | Select-Object Name, State, Generation, ProcessorCount, MemoryAssigned)

Sec 'Objetos NAT existentes' (Get-NetNat | Select-Object Name, InternalIPInterfaceAddressPrefix, Active)

Sec 'Direcciones IPv4 del host' (Get-NetIPAddress -AddressFamily IPv4 |
    Select-Object InterfaceAlias, IPAddress, PrefixLength, PrefixOrigin | Sort-Object InterfaceAlias)

Sec 'Adaptadores de red fisicos' (Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed)

Sec 'Ubicacion por defecto de discos Hyper-V' (Get-VMHost | Select-Object VirtualMachinePath, VirtualHardDiskPath)

Sec 'Espacio en disco' (Get-PSDrive C | Select-Object Used, Free)

Add-Content -Path $log -Value ""
Add-Content -Path $log -Value "=== FIN PREFLIGHT ==="
