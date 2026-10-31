# Fase 1 - Reinsertar la ISO y reiniciar al instalador (requiere elevacion)
$ErrorActionPreference = 'Stop'
$log = 'C:\Users\I5\Documents\Proyectos Web\TareaTaller\00-documentacion\salida-f1-reinstalar.log'
Start-Transcript -Path $log -Append | Out-Null

$nombre = 'srv-universidad'
$iso    = 'C:\Users\I5\Downloads\ubuntu-24.04.5-live-server-amd64.iso'

if (-not (Test-Path $iso)) { throw "No existe la ISO en $iso" }

Write-Host "== Reinsertando la ISO =="
$dvd = Get-VMDvdDrive -VMName $nombre
Set-VMDvdDrive -VMName $nombre -Path $iso
Write-Host "ISO montada ahora: $((Get-VMDvdDrive -VMName $nombre).Path)"

$dvd = Get-VMDvdDrive -VMName $nombre
$hdd = Get-VMHardDiskDrive -VMName $nombre
$net = Get-VMNetworkAdapter -VMName $nombre
Set-VMFirmware -VMName $nombre -BootOrder @($dvd, $hdd, $net)

Write-Host "== Reinicio forzado =="
$vm = Get-VM -Name $nombre
if ($vm.State -ne 'Off') { Stop-VM -Name $nombre -TurnOff -Force; Start-Sleep -Seconds 3 }
Start-VM -Name $nombre
Start-Sleep -Seconds 5

Write-Host "== Verificacion =="
Get-VM -Name $nombre | Format-List Name, State, Uptime
Write-Host "-- Orden de arranque --"
(Get-VMFirmware -VMName $nombre).BootOrder | ForEach-Object { "$($_.BootType) : $($_.Device.Name)" }
Write-Host "-- DVD --"
Get-VMDvdDrive -VMName $nombre | Format-List Path

Start-Process -FilePath vmconnect.exe -ArgumentList "$env:COMPUTERNAME", $nombre | Out-Null
Write-Host "== FIN =="
Stop-Transcript | Out-Null
