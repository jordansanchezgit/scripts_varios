# Establece la ruta donde se buscarán los archivos para borrar
$userTempPath = [System.IO.Path]::GetTempPath()
$windowsTempPath = "C:\Windows\Temp"

# Ruta del archivo de log
$logFilePath = "$env:USERPROFILE\Desktop\accion.log"

# Función para escribir mensajes en la consola y en el archivo de log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    
    # Escribe en la consola
    Write-Host $logMessage

    # Escribe en el archivo de log
    Add-Content -Path $logFilePath -Value $logMessage
}

# Verifica si el archivo de log existe, si no, lo crea
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File -Force
}

# Función para eliminar archivos en una ruta específica
function Clear-TempFiles {
    param (
        [string]$path
    )

    try {
        $files = Get-ChildItem -Path $path -Recurse -ErrorAction Stop
        foreach ($file in $files) {
            try {
                # Verifica si el archivo o carpeta existe antes de intentar eliminarlo
                if (Test-Path -Path $file.FullName) {
                    Remove-Item -Path $file.FullName -Force -Recurse -ErrorAction Stop
                    Write-Log "El archivo o carpeta $($file.FullName) ha sido eliminado."
                } else {
                    Write-Log "El archivo o carpeta $($file.FullName) no existe."
                }
            } catch [System.IO.IOException] {
                Write-Log "El archivo o carpeta $($file.FullName) está en uso y no se pudo eliminar. Detalles: $_"
            } catch [System.Exception] {
                Write-Log "No se pudo eliminar el archivo o carpeta $($file.FullName). Detalles: $_"
            }
        }
    } catch {
        Write-Log "No se pudo acceder a la ruta $path. Detalles: $_"
    }
}

# Elimina archivos temporales del usuario
Write-Log "Eliminando archivos temporales del usuario en $userTempPath"
Clear-TempFiles -path $userTempPath

# Elimina archivos temporales de Windows
Write-Log "Eliminando archivos temporales de Windows en $windowsTempPath"
Clear-TempFiles -path $windowsTempPath

Write-Log "Proceso de eliminación de archivos temporales completado."
