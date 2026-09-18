[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low")]
param (
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$path = @(
        "C:\Data\Backups\SQL",
        "C:\Users\kalvarado\OneDrive - AyS Comunicaciones de Venezuela\Respaldos Automaticos\SQL"
    ),

    [ValidateRange(1, 3650)]
    [int]$retentionDays = 7,

    [ValidateNotNullOrEmpty()]
    [string[]]$fileExtensions = @("*.bak", "*.zip", "*.rar"),

    [switch]$Delete
)

$ErrorActionPreference = "Stop"

$extensions = @(
    $fileExtensions |
        ForEach-Object {
            $extension = $_.Trim().TrimStart("*").ToLowerInvariant()
            if ($extension -and -not $extension.StartsWith(".")) {
                $extension = ".$extension"
            }
            if ($extension) {
                $extension
            }
        } |
        Select-Object -Unique
)

if ($extensions.Count -eq 0) {
    throw "Debe especificarse al menos una extensión válida."
}

$dateLimit = (Get-Date).AddDays(-$retentionDays)

function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$logFilePath,

        [Parameter(Mandatory)]
        [string]$message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $logFilePath -Value "$timestamp - $message" -Encoding UTF8 -ErrorAction Stop
}

$mode = if ($Delete) { "BORRADO" } else { "SIMULACION" }
Write-Host "Iniciando el proceso en modo $mode para $($path.Count) rutas..."

foreach ($configuredPath in $path) {
    try {
        $rootPath = (Resolve-Path -LiteralPath $configuredPath -ErrorAction Stop).ProviderPath
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
            throw "La ruta no es una carpeta: $rootPath"
        }
    } catch {
        Write-Warning "No se puede acceder a la ruta '$configuredPath'. Detalles: $($_.Exception.Message)"
        continue
    }

    $logFilePath = Join-Path -Path $rootPath -ChildPath "accion.log"

    try {
        if (-not (Test-Path -LiteralPath $logFilePath -PathType Leaf)) {
            New-Item -Path $logFilePath -ItemType File -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        Write-Warning "No se pudo crear o acceder al archivo de log '$logFilePath'. Detalles: $($_.Exception.Message)"
        continue
    }

    Write-Log -logFilePath $logFilePath -message "Inicio del proceso en modo $mode. Ruta: $rootPath. Antigüedad: $retentionDays días."

    try {
        $files = @(
            Get-ChildItem -LiteralPath $rootPath -File -Recurse -Force -ErrorAction Stop |
                Where-Object {
                    ($extensions -contains $_.Extension.ToLowerInvariant()) -and
                    ($_.LastWriteTime -lt $dateLimit) -and
                    (($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0)
                }
        )
    } catch {
        Write-Log -logFilePath $logFilePath -message "No se pudo revisar toda la estructura de carpetas. Detalles: $($_.Exception.Message)"
        Write-Warning "No se pudo revisar la ruta '$rootPath'. Detalles: $($_.Exception.Message)"
        continue
    }

    foreach ($file in $files) {
        if (-not $Delete) {
            Write-Host "[SIMULACION] Se eliminaría: $($file.FullName)"
            Write-Log -logFilePath $logFilePath -message "[SIMULACION] Se eliminaría: $($file.FullName)"
            continue
        }

        try {
            $currentFile = Get-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            $currentExtension = $currentFile.Extension.ToLowerInvariant()
            $isReparsePoint = ($currentFile.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

            if ($currentFile.PSIsContainer -or
                $isReparsePoint -or
                ($extensions -notcontains $currentExtension) -or
                ($currentFile.LastWriteTime -ge $dateLimit)) {
                Write-Log -logFilePath $logFilePath -message "Omitido porque ya no cumple los criterios: $($file.FullName)"
                continue
            }

            if ($PSCmdlet.ShouldProcess($currentFile.FullName, "Eliminar archivo de backup antiguo")) {
                Remove-Item -LiteralPath $currentFile.FullName -Force -ErrorAction Stop
                Write-Host "El archivo $($currentFile.FullName) ha sido borrado."
                Write-Log -logFilePath $logFilePath -message "El archivo $($currentFile.FullName) ha sido borrado."
            }
        } catch {
            Write-Warning "No se pudo borrar el archivo $($file.FullName). Detalles: $($_.Exception.Message)"
            Write-Log -logFilePath $logFilePath -message "No se pudo borrar el archivo $($file.FullName). Detalles: $($_.Exception.Message)"
        }
    }

    Write-Host "Proceso completado para la ruta '$rootPath'."
    Write-Log -logFilePath $logFilePath -message "Proceso de eliminación de archivos antiguos completado."
}

Write-Host "Proceso de eliminación de archivos antiguos completado para todas las rutas."
