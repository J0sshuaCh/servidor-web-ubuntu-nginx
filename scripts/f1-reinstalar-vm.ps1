# Fase 1 - Reinicio al instalador para reinstalar (requiere elevacion)
$ErrorActionPreference = 'Stop'
$log = 'C:\Users\I5\Documents\Proyectos Web\TareaTaller\00-documentacion\salida-f1-reinstalar.log'
Start-Transcript -Path $log -Force | Out-Null

$nombre = 'srv-universidad'
$vm = Get-VM -Name $nombre -ErrorAction Stop
Write-Host "Estado actual: $($vm.State)"

# Garantizar que la ISO siga montada y sea el primer dispositivo de arranque
$dvd = Get-VMDvdDrive -VMName $nombre
$hdd = Get-VMHardDiskDrive -VMName $nombre
$net = Get-VMNetworkAdapter -VMName $nombre
Set-VMFirmware -VMName $nombre -BootOrder @($dvd, $hdd, $net)
Write-Host "ISO montada: $($dvd.Path)"
Write-Host "Orden de arranque: DVD -> Disco -> Red"

if ($vm.State -ne 'Off') {
    Write-Host "Apagando la VM (equivale a mantener pulsado el boton de encendido)..."
    Stop-VM -Name $nombre -TurnOff -Force
    Start-Sleep -Seconds 3
}

Write-Host "Arrancando de nuevo desde la ISO del instalador..."
Start-VM -Name $nombre
Start-Sleep -Seconds 5

Get-VM -Name $nombre | Format-List Name, State, Uptime, MemoryAssigned

Write-Host "Abriendo consola..."
Start-Process -FilePath vmconnect.exe -ArgumentList "$env:COMPUTERNAME", $nombre | Out-Null

Write-Host "== FIN =="
Stop-Transcript | Out-Null
