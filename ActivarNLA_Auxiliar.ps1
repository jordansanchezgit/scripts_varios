$rutaScript="C:\PowerShells"

$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=MyScriptSigningCert" -KeyExportPolicy Exportable -CertStoreLocation "Cert:\CurrentUser\My"

$certPath = "Cert:\CurrentUser\My\$($cert.Thumbprint)"
Export-PfxCertificate -Cert $certPath -FilePath "${rutaScript}\MyScriptSigningCert.pfx" -Password (ConvertTo-SecureString -String "MyPassword" -Force -AsPlainText)


$cert = Get-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)"
Set-AuthenticodeSignature -FilePath "$($rutaScript)\ActivarNLA.ps1" -Certificate $cert

Get-AuthenticodeSignature -FilePath "$($rutaScript)\ActivarNLA.ps1"

Get-ExecutionPolicy
Set-ExecutionPolicy RemoteSigned
