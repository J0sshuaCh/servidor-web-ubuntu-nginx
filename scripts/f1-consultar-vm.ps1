# Fase 1 - Consulta del estado real de la VM y de la IP del invitado (requiere elevacion)
$ErrorActionPreference = 'SilentlyContinue'
$log = 'C:\Users\I5\Documents\Proyectos Web\TareaTaller\00-documentacion\salida-f1-consulta-vm.log'
Start-Transcript -Path $log -Force | Out-Null

$nombre = 'srv-universidad'
Write-Host "== Maquina virtual =="
Get-VM -Name $nombre | Format-List Name, State, Generation, ProcessorCount, MemoryStartup, MemoryAssigned, Uptime, Version

Write-Host "== Adaptador de red y IP vista por el invitado (KVP) =="
Get-VMNetworkAdapter -VMName $nombre | Format-List Name, SwitchName, MacAddress, Status, IPAddresses

Write-Host "== Servicios de integracion =="
Get-VMIntegrationService -VMName $nombre | Format-Table Name, Enabled, PrimaryStatusDescription -AutoSize

Write-Host "== Conmutador srv-lab =="
Get-VMSwitch -Name 'srv-lab' | Format-List Name, SwitchType, NetAdapterInterfaceDescription

Write-Host "== IP del host en srv-lab =="
Get-NetIPAddress -InterfaceAlias 'vEthernet (srv-lab)' -AddressFamily IPv4 | Format-List IPAddress, PrefixLength, AddressState

Write-Host "== NAT =="
Get-NetNat | Format-Table Name, InternalIPInterfaceAddressPrefix, Active -AutoSize

Write-Host "== Vecinos ARP conocidos en la subred del laboratorio =="
Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.150.*' } |
    Format-Table IPAddress, LinkLayerAddress, State -AutoSize

Write-Host "== FIN =="
Stop-Transcript | Out-Null
