# Publicar uma versão

Os APKs são distribuídos pela página **Releases** do GitHub.

## Chave de assinatura (uma vez só)

Todas as versões precisam ser assinadas com a **mesma chave**; senão o Android não atualiza o app instalado. Guarde o arquivo `.jks` e as senhas fora do repositório (gerenciador de senhas + backup). Perder a chave impede publicar atualizações.

```bash
keytool -genkeypair -v -keystore ~/sampletag-upload.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload
chmod 600 ~/sampletag-upload.jks
```

Para builds locais assinados, crie `android/key.properties` (já ignorado pelo git):

```properties
storeFile=/caminho/para/sampletag-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Conferir a assinatura de um APK:

```bash
$ANDROID_HOME/build-tools/36.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## A cada versão

1. Aumente `version:` no `pubspec.yaml` (`nome+código`, ex.: `1.1.0+2`). O código depois do `+` precisa sempre aumentar.
2. Compile: `flutter build apk --release --split-per-abi`.
3. Commit e push.
4. Publique a Release com a tag `v<nome>` (ex.: `v1.1.0`):
   - **pelo site:** *Releases → Draft a new release*, crie a tag, anexe `app-arm64-v8a-release.apk` (a maioria dos celulares) e `app-armeabi-v7a-release.apk` (celulares antigos de 32 bits) e publique;
   - **pelo terminal:** `gh release create v1.1.0 build/app/outputs/flutter-apk/*.apk --generate-notes`.

## Publicação automática (GitHub Actions)

O workflow `.github/workflows/release.yml` roda ao enviar uma tag `v*`: confere se a tag bate com o `pubspec.yaml`, roda `flutter analyze` e `flutter test`, compila os APKs (arm64-v8a, armeabi-v7a, x86_64 e universal, com `SHA256SUMS.txt`) e cria a Release.

Ele precisa destes segredos no repositório (cada comando pede o valor):

```bash
base64 -i ~/sampletag-upload.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_PASSWORD
gh secret set ANDROID_KEY_ALIAS --body upload
```

**Atenção:** sem os segredos, criar a tag (inclusive pelo site) dispara o workflow e ele falha. Isso não afeta uma Release publicada à mão, mas deixa um aviso vermelho em *Actions*. Se a publicação for sempre manual, o workflow pode ser removido.
