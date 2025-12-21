# Configurar Assinatura do APK

## Passo 1: Gerar Keystore

```bash
cd ~/Área\ de\ trabalho/BibliApp_web/bibli_app/android/app

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Responda as perguntas:
# - Senha da keystore: [ESCOLHA UMA SENHA FORTE]
# - Nome e sobrenome: Seu Nome
# - Unidade organizacional: BibliApp
# - Organização: Seu Nome
# - Cidade: Sua Cidade
# - Estado: Seu Estado
# - Código do país: BR
```

**IMPORTANTE**: Guarde a senha em local seguro!

---

## Passo 2: Criar `key.properties`

```bash
cd ~/Área\ de\ trabalho/BibliApp_web/bibli_app/android

cat > key.properties << EOF
storePassword=SUA_SENHA_AQUI
keyPassword=SUA_SENHA_AQUI
keyAlias=upload
storeFile=upload-keystore.jks
EOF
```

**Substitua `SUA_SENHA_AQUI` pela senha que você escolheu!**

---

## Passo 3: Configurar `build.gradle`

Arquivo: `android/app/build.gradle`

Adicione ANTES de `android {`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... configurações existentes
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## Passo 4: Adicionar ao `.gitignore`

```bash
cd ~/Área\ de\ trabalho/BibliApp_web/bibli_app

# Adicionar ao .gitignore
echo "android/key.properties" >> .gitignore
echo "android/app/upload-keystore.jks" >> .gitignore
```

---

## Passo 5: Build Release

```bash
cd ~/Área\ de\ trabalho/BibliApp_web/bibli_app

# APK otimizado
flutter build apk --release --split-per-abi --target-platform android-arm64

# Ou App Bundle
flutter build appbundle --release
```

---

## ⚠️ BACKUP DA KEYSTORE

**CRÍTICO**: Faça backup da keystore!

```bash
# Copiar para local seguro
cp android/app/upload-keystore.jks ~/Documentos/BibliApp_keystore_BACKUP.jks

# Anotar senha em local seguro (gerenciador de senhas)
```

**Se perder a keystore, não poderá atualizar o app na Play Store!**

---

## 🚀 Resultado

APK assinado em:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~35-40MB)

App Bundle em:
- `build/app/outputs/bundle/release/app-release.aab` (~40MB)

---

## Alternativa Rápida (Sem Assinatura)

Para testes locais sem assinatura:

```bash
flutter build apk --debug --split-per-abi --target-platform android-arm64
```

APK debug em: `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`

**Nota**: APK debug é maior (~60-70MB) e não pode ser publicado.
