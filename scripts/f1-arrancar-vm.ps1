# Fase 1 - Correccion de arranque e inicio de la VM (requiere elevacion)
$ErrorActionPreference = 'Stop'
$log = 'C:\Users\I5\Documents\Proyectos Web\TareaTaller\00-documentacion\salida-f1-arranque.log'
Start-Transcript -Path $log -Force | Out-Null

$nombre = 'srv-universidad'
$vm = Get-VM -Name $nombre -ErrorAction Stop
Write-Host "Estado inicial: $($vm.State)"

if ($vm.State -ne 'Off') {
    Write-Host "La VM ya esta encendida; no se reinicia." -ForegroundColor Yellow
} else {
    Write-Host "== Ajustes previos al primer arranque =="
    Set-VMNetworkAdapter -VMName $nombre -DynamicMacAddress
    $dvd = Get-VMDvdDrive -VMName $nombre
    $hdd = Get-VMHardDiskDrive -VMName $nombre
    $net = Get-VMNetworkAdapter -VMName $nombre
    Set-VMFirmware -VMName $nombre -BootOrder @($dvd, $hdd, $net)
    Write-Host "Orden de arranque configurado: DVD -> Disco duro -> Red"

    Write-Host "== Arrancando la VM =="
    Start-VM -Name $nombre
    Start-Sleep -Seconds 5
}

Write-Host "== Verificacion =="
Get-VM -Name $nombre | Format-List Name, State, Generation, ProcessorCount, MemoryAssigned, Uptime
Write-Host "-- Secure Boot --"
(Get-VMFirmware -VMName $nombre).SecureBoot
Write-Host "-- Orden de arranque efectivo --"
(Get-VMFirmware -VMName $nombre).BootOrder | ForEach-Object {
    if ($_.BootType -eq 'Drive') { "Drive : $($_.Device.Name)" } else { "$($_.BootType) : $($_.Device.Name)" }
}
Write-Host "-- MAC de la VM --"
Get-VMNetworkAdapter -VMName $nombre | Format-List Name, SwitchName, MacAddress, DynamicMacAddressEnabled
Write-Host "-- Salida a Internet desde el host hacia la subred del laboratorio --"
Get-NetNat | Select-Object Name, InternalIPInterfaceAddressPrefix | Format-Table -AutoSize

Write-Host "Abriendo consola (vmconnect)..."
Start-Process -FilePath vmconnect.exe -ArgumentList "$env:COMPUTERNAME", $nombre | Out-Null

Write-Host "== FIN =="
Stop-Transcript | Out-Null
