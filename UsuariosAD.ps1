# Importar el módulo de Active Directory si aún no está cargado
Import-Module ActiveDirectory

# Definir la ruta y nombre del archivo CSV donde se exportará la lista de usuarios
$csvFilePath = "C:\usuarios.csv"

# Obtener todos los usuarios de Active Directory
$users = Get-ADUser -Filter * -Properties SamAccountName, DisplayName, EmailAddress, Enabled, OfficePhone, MobilePhone

# Verificar si se encontraron usuarios
if ($users) {
    # Crear un arreglo para almacenar las líneas del CSV
    $csvLines = @()

    # Recorrer cada usuario y formatear la información según el ejemplo dado
    foreach ($user in $users) {
        $csvLine = @{
            'username'   = $user.SamAccountName
            'realname'   = $user.DisplayName
            'alias1'     = $user.SamAccountName
            'alias2'     = $user.EmailAddress
            'email'      = $user.EmailAddress
            'status'     = if ($user.Enabled) { 'active' } else { 'inactive' }
            'phone1'     = $user.OfficePhone
            'platform1'  = ''   # Ejemplo, ajustar según el entorno
            'phone2'     = $user.MobilePhone
            'platform2'  = ''   # Ejemplo, ajustar según el entorno
            'group1'     = ''         # Ajustar según los grupos del usuario
            'group2'     = ''         # Ajustar según los grupos del usuario
            'notes'      = ''         # Notas adicionales si es necesario
            'token1'     = ''         # Información del token si es necesario
            'type1'      = ''         # Tipo de usuario si es necesario
        }
        # Agregar la línea formateada al arreglo de líneas del CSV
        $csvLines += New-Object PSObject -Property $csvLine
    }

    # Exportar el arreglo de líneas del CSV al archivo CSV
    $csvLines | Export-Csv -Path $csvFilePath -NoTypeInformation -Force

    Write-Host "Lista de usuarios exportada correctamente a: $csvFilePath"
} else {
    Write-Warning "No se encontraron usuarios en Active Directory."
}
