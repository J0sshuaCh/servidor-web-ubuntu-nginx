# Fase 1 - Creacion de la VM srv-universidad en Hyper-V (requiere elevacion)
# Crea un conmutador interno con NAT y la VM. NO elimina nada existente.
# Si la VM ya existe, aborta sin tocar nada.

$ErrorActionPreference = 'Stop'
$log = 'C:\Users\I5\Documents\Proyectos Web\TareaTaller\00-documentacion\salida-f1-crear-vm.log'
Start-Transcript -Path $log -Force | Out-Null

$nombre  = 'srv-universidad'
$iso     = 'C:\Users\I5\Downloads\ubuntu-24.04.5-live-server-amd64.iso'
$base    = 'C:\Hyper-V'
$vmDir   = Join-Path $base $nombre
$vhdxDir = Join-Path $vmDir 'Virtual Hard Disks'
$cfgDir  = Join-Path $vmDir 'Virtual Machines'
$vhdx    = Join-Path $vhdxDir "$nombre.vhdx"

$switch   = 'srv-lab'
$ipHost   = '192.168.150.1'
$prefijo  = '192.168.150.0/24'
$natName  = 'srv-lab-nat'

Write-Host "== Verificaciones previas =="
if (Get-VM -Name $nombre -ErrorAction SilentlyContinue) {
    Write-Host "ABORTA: ya existe una VM llamada $nombre" -ForegroundColor Red
    Stop-Transcript | Out-Null
    return
}
if (-not (Test-Path $iso)) {
    Write-Host "ABORTA: no se encuentra la ISO en $iso" -ForegroundColor Red
    Stop-Transcript | Out-Null
    return
}

New-Item -ItemType Directory -Force -Path $vhdxDir, $cfgDir | Out-Null

Write-Host "== Conmutador interno $switch =="
if (-not (Get-VMSwitch -Name $switch -ErrorAction SilentlyContinue)) {
    New-VMSwitch -Name $switch -SwitchType Internal | Out-Null
    Write-Host "Creado conmutador interno '$switch'"
} else { Write-Host "El conmutador '$switch' ya existia" }

$aliasHost = "vEthernet ($switch)"
if (-not (Get-NetIPAddress -InterfaceAlias $aliasHost -IPAddress $ipHost -ErrorAction SilentlyContinue)) {
    New-NetIPAddress -InterfaceAlias $aliasHost -IPAddress $ipHost -PrefixLength 24 | Out-Null
    Write-Host "Asignada IP $ipHost/24 al host en $aliasHost"
} else { Write-Host "La IP $ipHost ya estaba asignada a $aliasHost" }

if (-not (Get-NetNat -Name $natName -ErrorAction SilentlyContinue)) {
    New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $prefijo | Out-Null
    Write-Host "Creado NAT '$natName' para $prefijo"
} else { Write-Host "El NAT '$natName' ya existia" }

Write-Host "== Creando VM $nombre =="
New-VM -Name $nombre -Generation 2 -MemoryStartupBytes 4GB `
    -NewVHDPath $vhdx -NewVHDSizeBytes 20GB -Path $cfgDir -SwitchName $switch | Out-Null

Write-Host "== Hardware de la VM =="
Set-VMProcessor -VMName $nombre -Count 2
Set-VMMemory -VMName $nombre -DynamicMemoryEnabled $false -StartupBytes 4GB
Set-VMFirmware -VMName $nombre -EnableSecureBoot Off
$dvd = Add-VMDvdDrive -VMName $nombre -Path $iso
Set-VMFirmware -VMName $nombre -FirstBootDevice $dvd
Set-VM -Name $nombre -AutomaticStartAction Nothing -AutomaticStopAction ShutDown

Write-Host "== Estado final =="
Write-Host "-- VM --"
Get-VM -Name $nombre | Format-List Name, State, Generation, ProcessorCount, MemoryAssigned, Path
Write-Host "-- Disco --"
Get-VMHardDiskDrive -VMName $nombre | Format-List Path, ControllerType, ControllerNumber
Write-Host "-- DVD --"
Get-VMDvdDrive -VMName $nombre | Format-List Path
Write-Host "-- Red de la VM --"
Get-VMNetworkAdapter -VMName $nombre | Format-List Name, SwitchName, MacAddress, Status
Write-Host "-- Orden de arranque --"
(Get-VMFirmware -VMName $nombre).BootOrder | Select-Object BootType, Device | Format-Table -AutoSize
Write-Host "-- Conmutadores --"
Get-VMSwitch | Select-Object Name, SwitchType | Format-Table -AutoSize
Write-Host "-- NAT --"
Get-NetNat | Select-Object Name, InternalIPInterfaceAddressPrefix | Format-Table -AutoSize
Write-Host "-- IP del host en el conmutador de laboratorio --"
Get-NetIPAddress -InterfaceAlias $aliasHost | Select-Object IPAddress, PrefixLength | Format-Table -AutoSize
Write-Host "-- Tamanio del VHDX --"
Get-ChildItem $vhdx | Select-Object Name, @{n='MB';e={[math]::Round($_.Length/1MB,1)}} | Format-Table -AutoSize

Write-Host "== FIN =="
Stop-Transcript | Out-Null
