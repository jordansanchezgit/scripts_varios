# Establece la ruta donde se buscarán los archivos para borrar
$path = "D:\Respaldos Automaticos\Historico Valery\"

# Define las extensiones de archivo a buscar
$fileExtensions = @("*.bak", "*.zip", "*.rar")

# Calcula la fecha límite (30 días atrás)
$dateLimit = (Get-Date).AddDays(-30)

# Establece la ruta del archivo de log
$logFilePath = Join-Path -Path $path -ChildPath "accion.log"

# Verifica si el archivo de log existe, si no, lo crea
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File -Force
}

# Función para escribir mensajes en el archivo de log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Obtiene la unidad del directorio especificado
$drive = Get-PSDrive -Name (Get-Item -Path $path).PSDrive.Name

# Calcula el porcentaje de espacio libre en disco
$freeSpacePercentage = ($drive.Free / ($drive.Free + $drive.Used)) * 100

# Verifica si el porcentaje de espacio libre es menor o igual al 30%
if ($freeSpacePercentage -le 30) {
    Write-Host "El espacio libre en disco es $freeSpacePercentage%. Procediendo a borrar archivos..."
    Write-Log "El espacio libre en disco es $freeSpacePercentage%. Procediendo a borrar archivos..."

    # Itera sobre cada tipo de archivo
    foreach ($extension in $fileExtensions) {
        # Obtiene los archivos con la extensión especificada y que sean anteriores a la fecha límite
        $files = Get-ChildItem -Path $path -Filter $extension | Where-Object { $_.LastWriteTime -lt $dateLimit }
        
        # Borra los archivos
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force
                Write-Host "El archivo $($file.FullName) ha sido borrado."
                Write-Log "El archivo $($file.FullName) ha sido borrado."
            } catch {
                Write-Warning "No se pudo borrar el archivo $($file.FullName). Detalles: $_"
                Write-Log "No se pudo borrar el archivo $($file.FullName). Detalles: $_"
            }
        }
    }
} else {
    Write-Host "El espacio libre en disco es $freeSpacePercentage%. No es necesario borrar archivos."
    Write-Log "El espacio libre en disco es $freeSpacePercentage%. No es necesario borrar archivos."
}
