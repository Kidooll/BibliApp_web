# Guia de Fingerprint para BibliApp

## Fingerprints Atuais

### Keystore de Debug (Desenvolvimento)
- **SHA1:** `CB:21:3E:1D:4B:14:8D:C4:8E:6C:29:E7:20:B8:DF:CF:A0:8A:1D:AE`
- **SHA256:** `8A:7C:58:5D:06:FB:B8:91:5E:69:FF:D7:78:D1:FA:5B:27:07:63:B3:D6:1E:1E:4E:72:40:F9:3D:08:21:C7:9A`

## Como Obter Fingerprints

### 1. Fingerprint do Keystore de Debug
```powershell
# No PowerShell, execute:
& "C:\Program Files\Java\jdk-24\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### 2. Fingerprint do Keystore de Release (Após criar)
```powershell
# Execute o script create_keystore.ps1 primeiro
.\create_keystore.ps1

# Depois obtenha o fingerprint:
& "C:\Program Files\Java\jdk-24\bin\keytool.exe" -list -v -keystore "android\app\upload-keystore.jks" -alias upload -storepass bibliapp2024
```

## Configuração para Produção

### 1. Criar Keystore de Release
Execute o script `create_keystore.ps1` que foi criado:
```powershell
.\create_keystore.ps1
```

### 2. Configurar key.properties
O arquivo `android/key.properties` já foi criado com as configurações necessárias.

### 3. Build de Release
```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

## Uso dos Fingerprints

### Firebase
1. Vá para o console do Firebase
2. Selecione seu projeto
3. Vá em "Project Settings" > "General"
4. Role até "Your apps" e selecione o app Android
5. Clique em "Add fingerprint"
6. Adicione o fingerprint SHA1 ou SHA256

### Google Services
- Use o fingerprint SHA1 para configurações do Google Services
- Use o fingerprint SHA256 para configurações mais recentes

### Outros Serviços
- **Google Sign-In**: SHA1
- **Google Maps**: SHA1
- **Firebase Auth**: SHA1
- **Google Play Services**: SHA1

## Troubleshooting

### Erro: "keytool não é reconhecido"
Certifique-se de que o Java JDK está instalado e use o caminho completo:
```powershell
& "C:\Program Files\Java\jdk-24\bin\keytool.exe"
```

### Erro: "Keystore não encontrado"
O keystore de debug é criado automaticamente quando você executa o app pela primeira vez. Se não existir:
```powershell
# Execute o app uma vez
flutter run
```

### Erro: "Senha incorreta"
- Debug keystore: `android` (senha padrão)
- Release keystore: `bibliapp2024` (conforme configurado)

## Segurança

⚠️ **IMPORTANTE:**
- Nunca compartilhe seu keystore de release
- Mantenha o arquivo `key.properties` seguro
- Faça backup do keystore de release
- O keystore de debug pode ser compartilhado (é padrão para todos os desenvolvedores) 