# Desenvolvimento

Guia interno para compilar, testar e manter o SampleTag. Para publicar uma versão, veja [publicar-versao.md](publicar-versao.md).

## Requisitos

- Flutter 3.50+ (Dart 3.14+)
- Android SDK (API 36 para compilar; o app roda a partir da **API 24**, Android 7.0) e JDK 17

> **minSdk:** o pedido original era API 23, mas o Flutter 3.50 só suporta Android 7.0+ (API 24), que é o valor configurado.

No Mac usado no projeto, o JDK 17 do Homebrew não fica no `PATH`:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

## Compilar e executar

```bash
flutter pub get
dart run build_runner build     # gera lib/data/db/database.g.dart (já versionado)
flutter gen-l10n                # gera lib/l10n/app_localizations*.dart (já versionado)

flutter run                                   # aparelho/emulador conectado
flutter build apk --release --split-per-abi   # APKs em build/app/outputs/flutter-apk/
```

O build release é assinado com a chave definida em `android/key.properties` (ver [publicar-versao.md](publicar-versao.md)). Sem esse arquivo, o Gradle avisa e usa a chave de debug — esse APK **não** serve para atualizar instalações feitas com a chave de publicação.

## Arquitetura

```
lib/
  core/        tema, formatação, erros, widgets comuns
  domain/      modelos (Dart puro), geração de código, filtros, importação,
               modelos compartilhados, limites geográficos, dados iniciais
  data/        banco drift (tabelas, migrações) e repositórios
  services/    GPS, fotos, geocodificação
    export/    CSV, KML, QR, etiquetas PDF, relatório HTML, backup/importação
  features/    telas (samples, labels, scanner, map, templates, export, settings, home)
  l10n/        ARB (pt, en) para i18n
  providers.dart  Riverpod
assets/report/ template.html (placeholders {{...}}), leaflet.min.js, leaflet.min.css
assets/geo/    limites IBGE (UFs e municípios por UF)
assets/icon/   ícone em SVG/PNG
tool/          relatório de demonstração e geração de ícones
```

- **Estado:** Riverpod 3. **Banco:** drift/SQLite com migrações versionadas em `AppDatabase.migrations` (v2 acrescentou `samples.parent_id` para amostras técnicas).
- **UI:** Material 3 via `package:material_ui` (no Flutter 3.50 o Material saiu do SDK). Pacotes que ainda usam `package:flutter/material.dart` (flutter_map, printing, mobile_scanner) funcionam por meio do `MaterialUiCompatibilityBridge`.
- Os geradores (CSV, KML, HTML, PDF, QR) e as regras de importação são **Dart puro**, testáveis sem aparelho.
- As fotos ficam em `<documentos do app>/photos/` e o banco guarda só o nome do arquivo.

### Códigos das amostras

- Padrão `{PREFIXO}-{COLETOR}-{AAAA}-{SEQ4}` (ex.: `CAC-AS-2026-0001`). Tokens: `{PREFIXO}`, `{COLETOR}`, `{AAAA}`, `{AA}`, `{MM}`, `{DD}`, `{SEQ}`/`{SEQn}`.
- `{COLETOR}` é o código curto do aparelho (ou as iniciais do nome) e evita colisões entre celulares.
- Amostras técnicas usam `ORIGEM-01`, `ORIGEM-02`… (`nextChildCode`), que não interferem na sequência normal.
- Na importação, códigos repetidos podem ser renomeados com `-B`, `-C`…

### Formatos de arquivo

- **Backup/coleta (ZIP):** `sampletag_backup.json` (modelos, amostras, configurações; `format: sampletag-backup`), `sampletag.sqlite` (cópia via `VACUUM INTO`) e `photos/*.jpg`.
- **Modelo compartilhado (JSON):** `{format: "sampletag-template", version: 1, exportedAt, template}`. Na importação, modelo com mesmo id ou mesmo nome+prefixo é tratado como o mesmo; se diferente, o usuário escolhe atualizar ou importar como cópia.
- **CSV:** `;`, UTF-8 com BOM, proteção contra injeção de fórmula; coluna `amostra_origem` antes de `id`.

### Relatório HTML

Um único `.html` (`SampleTag_Relatorio_{projeto}_{AAAA-MM-DD}.html`), gerado por `HtmlReportBuilder` a partir de `assets/report/template.html` com substituição de placeholders em uma passada:

- Leaflet 1.9.4 (JS/CSS) e miniaturas das fotos (~400 px, JPEG 70%, base64) embutidos;
- fundos online: **satélite Esri** (padrão) e **ruas CARTO**. O servidor `tile.openstreetmap.org` recusa pedidos de páginas `file://` (exige `Referer`), por isso não é usado. Se uma camada online falhar sem carregar nenhum tile, o script volta para o fundo offline do IBGE e mostra um aviso;
- mapa estático em SVG (`buildSvgMap`): tudo dentro de `#svg-view` recebe a transformação de zoom; traços usam `vector-effect: non-scaling-stroke`; cada ponto é `<g class="pt" transform="translate(x y)">` com um grupo interno reescalado por `1/k`; o script recalcula a barra de escala (`data-km-per-unit`) e esconde rótulos sobrepostos;
- `<script type="application/json" id="samples-data">` com todos os dados (inclui `parentCode`);
- todo texto do usuário passa por `escapeHtml`/`jsonForScript`.

### Limites territoriais

`assets/geo/` (ver `FONTE.md`): malha intermediária do IBGE para as 27 UFs e 5.570 municípios. No app servem de mapa base e para preencher município/UF a partir do GPS sem internet (a geocodificação online fica como reserva). No relatório são simplificados (Douglas-Peucker) e codificados em formato "polyline" para manter o HTML leve. Para atualizar, baixe de novo da API de malhas do IBGE e reprocesse (coordenadas com 4 casas, propriedades `uf`/`c` e `n`).

### Ícone

`assets/icon/` (SVG; folha com etiqueta) é o ícone do app (adaptativo e monocromático no Android 8+/13+), a tela de abertura e aparece no relatório HTML. Para alterar, edite `tool/generate_icon_svgs.py` e rode (requer `brew install librsvg`):

```bash
cd assets/icon && python3 ../../tool/generate_icon_svgs.py && ../../tool/generate_android_icons.sh
```

O infográfico do README está em `docs/img/como-funciona.svg` (SVG escrito à mão; confira com `rsvg-convert -w 1600 docs/img/como-funciona.svg -o /tmp/info.png`).

## Testes

```bash
flutter analyze                                   # sem avisos
flutter test                                      # unitários + widget + fluxo
flutter test integration_test/app_flow_test.dart -d <aparelho>
dart run tool/generate_demo_report.dart           # relatório de demonstração em demo/
dart run tool/generate_demo_report.dart demo --pontos-proximos   # + plantas a poucos metros
```

- `test/sample_code_test.dart` — geração do código, `{COLETOR}` e iniciais.
- `test/import_test.dart` — planejamento da importação (novas, atualizadas, conflitos, modelos) e cenário completo de dois celulares.
- `test/exporters_test.dart` — CSV (escape, injeção de fórmula), KML e QR.
- `test/html_report_builder_test.dart` — gerador do HTML: autocontido, placeholders, JSON, escape contra injeção, mapa SVG.
- `test/data_test.dart` — banco (modelo Cacau, CRUD, rascunhos), filtros e PDF das etiquetas.
- `test/geo_test.dart` — limites IBGE: localização offline, codificação, simplificação e configurações do mapa.
- `test/child_samples_test.dart` — amostras técnicas (código, banco, exclusão em lote, migração v1→v2, CSV/KML) e arquivo de modelo compartilhado.
- `test/sample_form_widget_test.dart` — formulário, fluxo criar amostra → exportar relatório, seleção múltipla com exclusão e criação de amostra técnica.
- `integration_test/app_flow_test.dart` — mesmo fluxo em aparelho real.

O JavaScript do relatório não tem testes automatizados: confira no navegador (servindo a pasta com `python3 -m http.server` ou abrindo o arquivo direto).
