<p align="center">
  <img src="assets/icon/sampletag_icon.svg" alt="Ícone do SampleTag: folha verde com etiqueta amarela" width="128">
</p>

<h1 align="center">SampleTag</h1>

App Android (Flutter) para **registrar e etiquetar amostras de campo** (biológicas e técnicas), 100% offline, com exportação de um **relatório HTML autocontido** com mapa e todas as amostras.

## Funcionalidades

| Tela | O que faz |
|---|---|
| **Amostras** | Lista com busca (ignora acentos), filtros (modelo, período, coletor, município), ordenação e contador. Card com miniatura, código, data e município. |
| **Nova/editar amostra** | Escolha do modelo, código gerado automaticamente (editável; padrão `CAC-AS-2026-0001`, com o código do coletor), data/hora e coletor preenchidos, GPS com precisão em metros (aviso > 20 m e "Aguardar melhor precisão"), município/UF por geocodificação reversa (quando há internet), várias fotos (câmera/galeria, lado maior 1600 px, JPEG 80%), campos extras do modelo, **rascunho salvo automaticamente**. |
| **Detalhe** | Todos os dados, fotos (tela cheia com zoom), mini-mapa e QR code. |
| **Etiqueta** | PDF no layout da ficha (cabeçalho "FICHA DE AMOSTRA - {MODELO}", campos, QR com JSON compacto, rodapé com armazenamento) em 50×30 mm, 100×70 mm e A4 (8 por folha). Imprime e compartilha via `printing`. |
| **Escanear** | Lê o QR da etiqueta (ou digita o código) e abre a amostra. |
| **Mapa** | Todas as amostras (respeitando os filtros) em `flutter_map`. Fundo com limites de estados e municípios do IBGE embutidos (funciona sem internet); tiles OSM por cima quando há conexão. |
| **Modelos** | Criar/editar modelos: nome, prefixo, cor, categoria, armazenamento padrão e campos extras (texto, número, lista, data; obrigatórios ou não). Vem com **Cacau**. |
| **Exportar** | Relatório HTML, CSV (`;`, UTF-8 com BOM), KML (Google Earth/QGIS), backup ZIP (banco + fotos), restauração e **importação de coleta de outro celular**. Tudo pela folha de compartilhamento — nada sai do aparelho sem ação do usuário. |
| **Ajustes** | Coletor padrão, projeto/expedição, formato do código, **mapa base** (país, estados da coleta, limites municipais), tema claro/escuro e carga das 5 amostras de exemplo. |

### Juntar dados de vários celulares

1. **Cada celular tem um código de coletor** (Ajustes → "Código do coletor", ou as iniciais do nome). O formato padrão `{PREFIXO}-{COLETOR}-{AAAA}-{SEQ4}` gera `CAC-AS-2026-0001`, `CAC-JL-2026-0001`…, então dois celulares nunca criam o mesmo código. Na primeira amostra, se não houver código nem nome, o app pede.
2. **Cada coletor** usa *Exportar → Criar backup (ZIP)* e envia o arquivo a quem vai juntar os dados.
3. **Quem junta** usa *Exportar → Importar coleta de outro celular* para cada ZIP. A prévia mostra:
   - amostras novas, atualizadas (versão recebida mais recente), já iguais e com versão local mais recente;
   - **códigos repetidos** (amostras diferentes com o mesmo código), com a escolha *Renomear* (`…-B`), *Pular* ou *Substituir*, para todas ou uma a uma;
   - modelos de ficha novos (modelos com mesmo nome e prefixo são reaproveitados).
   A importação **não altera as configurações** de quem importa, copia só as fotos necessárias e pode ser repetida sem duplicar nada.
4. Com tudo no mesmo aparelho, gere o **Relatório HTML**.

*Restaurar backup deste aparelho* continua existindo para recuperar uma cópia própria (inclui configurações); se encontrar códigos repetidos, ele recusa e indica a importação.

### Relatório HTML

Um único `.html` (`SampleTag_Relatorio_{projeto}_{AAAA-MM-DD}.html`) que abre em qualquer navegador:

- Leaflet 1.9.4 (JS/CSS) e fotos (miniaturas ~400 px, JPEG 70%, base64) **embutidos**;
- **mapa base offline com limites do IBGE** (todas as UFs como contexto, UFs da coleta em destaque e, opcionalmente, seus municípios com nome ao passar o mouse). Funciona sem internet e abrindo o arquivo direto do disco; o OpenStreetMap é uma camada opcional no seletor do mapa;
- marcadores coloridos por modelo, `fitBounds`, agrupamento simples acima de 25 pontos e popup com código, data, coletor, clone, município/UF e miniatura;
- **mapa estático em SVG** (para impressão), com os mesmos limites, projeção equiretangular, grade lat/long, escala e norte;
- cabeçalho com projeto, período, data de geração e totais por modelo, coletor e município;
- tabela com todas as colunas, busca em tempo real, ordenação por coluna e filtro por modelo; clicar na linha centraliza o mapa e abre o popup;
- uma ficha por amostra (campos, campos personalizados, fotos e QR em SVG);
- `<script type="application/json" id="samples-data">` com todos os dados;
- botões **Baixar CSV** (gerado no navegador) e **Imprimir** (`@media print`: uma ficha por página);
- responsivo, com tema escuro, e todo texto do usuário escapado contra injeção de HTML.

Exemplo pronto: [`demo/SampleTag_Relatorio_Cacau_Sul_da_Bahia_2026-11-12.html`](demo/) — 5 amostras em fazendas de cacau de Ilhéus, Uruçuca, Itajuípe, Una e Camacan (nomes fictícios).

## Arquitetura

```
lib/
  core/        tema, formatação, erros, widgets comuns
  domain/      modelos (Dart puro), geração de código, filtros, dados iniciais
  data/        banco drift (tabelas, migrações) e repositórios
  services/    GPS, fotos, geocodificação
    export/    CSV, KML, QR, etiquetas PDF, relatório HTML, backup
  features/    telas (samples, labels, scanner, map, templates, export, settings, home)
  l10n/        ARB (pt, en) para i18n
  providers.dart  Riverpod
assets/report/ template.html (placeholders {{...}}), leaflet.min.js, leaflet.min.css
tool/          generate_demo_report.dart
```

- **Estado:** Riverpod 3. **Banco:** drift/SQLite com migrações versionadas em `AppDatabase.migrations`.
- **UI:** Material 3 via `package:material_ui` (no Flutter 3.50 o Material saiu do SDK). Pacotes que ainda usam `package:flutter/material.dart` (flutter_map, printing, mobile_scanner) funcionam por meio do `MaterialUiCompatibilityBridge`.
- Os geradores (CSV, KML, HTML, PDF, QR) são **Dart puro**, testáveis sem aparelho.
- **Ícone:** `assets/icon/` (SVG; folha com etiqueta). É o ícone do app (adaptativo e monocromático no Android 8+/13+), a tela de abertura e aparece no cabeçalho e como favicon do relatório HTML. Para alterar: edite `tool/generate_icon_svgs.py` e rode `cd assets/icon && python3 ../../tool/generate_icon_svgs.py && ../../tool/generate_android_icons.sh` (requer `brew install librsvg`).
- As fotos ficam em `<documentos do app>/photos/` e o banco guarda só o nome do arquivo.
- **Limites territoriais** (`assets/geo/`, ver `FONTE.md`): malha intermediária do IBGE para as 27 UFs e 5.570 municípios. No app servem de mapa base e para **preencher município/UF a partir do GPS sem internet** (a geocodificação online fica como reserva). No relatório são simplificados (Douglas-Peucker) e codificados em formato "polyline" para manter o HTML leve (~170 KB de limites com a Bahia e seus 417 municípios; o relatório de exemplo inteiro tem ~470 KB).
- Para atualizar os limites, baixe de novo da API de malhas do IBGE e reprocesse (coordenadas com 4 casas, propriedades `uf`/`c` e `n`).

## Requisitos

- Flutter 3.50+ (Dart 3.14+)
- Android SDK (API 24+) e JDK 17

> **minSdk:** o pedido original era API 23, mas o Flutter 3.50 só suporta Android 7.0+ (**API 24**), que é o valor configurado.

## Build e execução

```bash
flutter pub get
dart run build_runner build     # gera lib/data/db/database.g.dart (já versionado)
flutter gen-l10n                # gera lib/l10n/app_localizations*.dart (já versionado)

flutter run                     # aparelho/emulador conectado
flutter build apk --release     # build/app/outputs/flutter-apk/app-release.apk
```

O build release usa a chave de debug — configure sua assinatura em `android/app/build.gradle.kts` antes de publicar.

## Publicar uma versão (GitHub Releases)

O workflow `.github/workflows/release.yml` roda testes, compila e publica os APKs (arm64-v8a, armeabi-v7a, x86_64 e universal, com `SHA256SUMS.txt`) numa Release sempre que uma tag `v*` é enviada.

**Uma vez só — chave de assinatura.** Todas as versões precisam ser assinadas com a **mesma chave**; senão o Android não atualiza o app instalado. Guarde o arquivo e as senhas fora do repositório (gerenciador de senhas + backup).

```bash
keytool -genkeypair -v -keystore ~/sampletag-upload.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload

# Segredos do repositório (cada comando pede o valor)
base64 -i ~/sampletag-upload.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_PASSWORD
gh secret set ANDROID_KEY_ALIAS --body upload
```

Para builds locais assinados, crie `android/key.properties` (já ignorado pelo git):

```properties
storeFile=/caminho/para/sampletag-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Sem esse arquivo o build release usa a chave de debug (o Gradle avisa).

**A cada versão:**

```bash
# 1. pubspec.yaml: version: 1.1.0+2   (nome+código; o código sempre aumenta)
git commit -am "Versão 1.1.0"
git push
# 2. a tag precisa bater com o nome da versão
git tag v1.1.0
git push origin v1.1.0
```

Acompanhe em *Actions*; ao terminar, a Release aparece em *Releases* com os APKs. Sem Actions, dá para publicar à mão: `gh release create v1.1.0 build/app/outputs/flutter-apk/*.apk --generate-notes`.

## Testes

```bash
flutter analyze                                   # sem avisos
flutter test                                      # unitários + widget + fluxo
flutter test integration_test/app_flow_test.dart -d <device>
dart run tool/generate_demo_report.dart           # relatório de demonstração em demo/
```

- `test/sample_code_test.dart` — geração do código, `{COLETOR}` e iniciais.
- `test/import_test.dart` — planejamento da importação (novas, atualizadas, conflitos, modelos) e cenário completo de dois celulares (backup → importação → reimportação).
- `test/exporters_test.dart` — CSV (escape, injeção de fórmula), KML e QR.
- `test/html_report_builder_test.dart` — gerador do HTML: autocontido, placeholders, JSON, escape contra injeção, mapa SVG.
- `test/data_test.dart` — banco (modelo Cacau, CRUD, rascunhos), filtros e PDF das etiquetas.
- `test/geo_test.dart` — limites IBGE: localização offline de UF/município, codificação, simplificação e configurações do mapa.
- `test/sample_form_widget_test.dart` — formulário (validação e salvamento) e fluxo criar amostra → exportar relatório.
- `integration_test/app_flow_test.dart` — mesmo fluxo em aparelho real.

## Permissões e privacidade

- **Câmera** (fotos e leitura de QR) e **localização** (coordenadas) são pedidas só no momento do uso, com explicação antes.
- **Internet** é opcional: só para tiles do mapa e geocodificação reversa.
- Erros tratados: GPS desligado (atalho para ativar), permissão negada/bloqueada (atalho para ajustes), sem sinal (tempo-limite) e armazenamento cheio.
