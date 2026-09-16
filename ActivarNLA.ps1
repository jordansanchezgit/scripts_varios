

# Habilitar NLA mediante el Registro de Windows
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$regName = "UserAuthentication"
$regValue = 1

# Crear la clave de registro si no existe
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Establecer el valor en el registro
Set-ItemProperty -Path $regPath -Name $regName -Value $regValue

# Confirmar el cambio
if ((Get-ItemProperty -Path $regPath -Name $regName).$regName -eq $regValue) {
    Write-Output "Autenticación a nivel de red (NLA) habilitada correctamente."
} else {
    Write-Output "No se pudo habilitar la autenticación a nivel de red (NLA)."
}

# Habilitar RDP y NLA mediante WMI
try {
    # Habilitar el servicio de Escritorio Remoto
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

    # Habilitar NLA en RDP
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

    Write-Output "Configuración de Escritorio Remoto y NLA completada."
} catch {
    Write-Error "Error al configurar Escritorio Remoto y NLA: $_"
}