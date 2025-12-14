# Script para criar keystore de release para o BibliApp
# Execute este script no PowerShell como administrador

Write-Host "=== Criando Keystore de Release para BibliApp ===" -ForegroundColor Green

# Parâmetros do keystore
$KEYSTORE_PATH = "android\app\upload-keystore.jks"
$KEY_ALIAS = "upload"
$KEY_PASSWORD = "bibliapp2024"
$STORE_PASSWORD = "bibliapp2024"

# Informações do certificado
$CERT_CN = "BibliApp"
$CERT_OU = "Development"
$CERT_O = "BibliApp"
$CERT_C = "BR"

Write-Host "Criando keystore em: $KEYSTORE_PATH" -ForegroundColor Yellow

# Comando para criar o keystore
$keytoolCmd = "& 'C:\Program Files\Java\jdk-24\bin\keytool.exe' -genkey -v -keystore `"$KEYSTORE_PATH`" -alias `"$KEY_ALIAS`" -keyalg RSA -keysize 2048 -validity 10000 -storepass `"$STORE_PASSWORD`" -keypass `"$KEY_PASSWORD`" -dname `"CN=$CERT_CN, OU=$CERT_OU, O=$CERT_O, C=$CERT_C`""

Write-Host "Executando comando..." -ForegroundColor Yellow
Invoke-Expression $keytoolCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "Keystore criado com sucesso!" -ForegroundColor Green
    
    # Obter o fingerprint do novo keystore
    Write-Host "`n=== Fingerprint do Keystore de Release ===" -ForegroundColor Green
    $fingerprintCmd = "& 'C:\Program Files\Java\jdk-24\bin\keytool.exe' -list -v -keystore `"$KEYSTORE_PATH`" -alias `"$KEY_ALIAS`" -storepass `"$STORE_PASSWORD`""
    Invoke-Expression $fingerprintCmd
    
    Write-Host "`n=== Próximos Passos ===" -ForegroundColor Green
    Write-Host "1. Configure o arquivo key.properties em android/key.properties" -ForegroundColor Yellow
    Write-Host "2. Atualize o build.gradle.kts para usar o keystore de release" -ForegroundColor Yellow
    Write-Host "3. Use o fingerprint SHA1 ou SHA256 acima para configurar serviços externos" -ForegroundColor Yellow
} else {
    Write-Host "Erro ao criar o keystore!" -ForegroundColor Red
} 