// Compartilhamento de modelos de ficha entre celulares. Dart puro.
//
// O modelo vira um arquivo JSON pequeno (`SampleTag_Modelo_Cacau.json`) que
// pode ser enviado por WhatsApp, e-mail etc. e importado em outro aparelho.

import 'dart:convert';

import 'models.dart';

const templateFileFormat = 'sampletag-template';
const templateFileVersion = 1;

/// Conteúdo do arquivo de modelo.
String encodeTemplateFile(SampleTemplate t, {DateTime? exportedAt}) =>
    const JsonEncoder.withIndent('  ').convert({
      'format': templateFileFormat,
      'version': templateFileVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'template': t.toJson(),
    });

/// Lê o arquivo de modelo. Lança [FormatException] com mensagem amigável.
SampleTemplate decodeTemplateFile(List<int> bytes) {
  Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes, allowMalformed: true).replaceFirst('﻿', ''));
  } on FormatException {
    throw const FormatException('O arquivo não é um modelo do SampleTag.');
  }
  if (json is! Map || json['format'] != templateFileFormat || json['template'] is! Map) {
    throw const FormatException('O arquivo não é um modelo do SampleTag.');
  }
  final version = json['version'];
  if (version is int && version > templateFileVersion) {
    throw const FormatException('Modelo criado por uma versão mais nova do SampleTag. Atualize o app.');
  }
  try {
    final t = SampleTemplate.fromJson((json['template'] as Map).cast<String, Object?>());
    if (t.id.trim().isEmpty || t.name.trim().isEmpty || t.codePrefix.trim().isEmpty) {
      throw const FormatException('Modelo incompleto (sem nome ou prefixo).');
    }
    return t;
  } on FormatException {
    rethrow;
  } on Object {
    throw const FormatException('Modelo com dados inválidos.');
  }
}

/// Como um modelo recebido se relaciona com os modelos deste aparelho.
enum TemplateMatch {
  /// Não existe aqui.
  none,

  /// Já existe e é idêntico.
  identical,

  /// Mesmo modelo (mesmo id, ou mesmo nome e prefixo), com diferenças.
  differs,
}

/// Procura o modelo local correspondente ao recebido.
(TemplateMatch, SampleTemplate?) matchTemplate(SampleTemplate incoming, List<SampleTemplate> local) {
  String key(SampleTemplate t) => '${t.name.trim().toLowerCase()}|${t.codePrefix.trim().toUpperCase()}';
  final same = local.where((t) => t.id == incoming.id).firstOrNull ??
      local.where((t) => key(t) == key(incoming)).firstOrNull;
  if (same == null) return (TemplateMatch.none, null);
  final a = jsonEncode({...same.toJson(), 'id': ''});
  final b = jsonEncode({...incoming.toJson(), 'id': ''});
  return (a == b ? TemplateMatch.identical : TemplateMatch.differs, same);
}

/// Cópia com novo id e nome sem repetir os existentes ("Cacau (2)").
SampleTemplate templateCopy(SampleTemplate t, String newId, List<SampleTemplate> local) {
  final names = local.map((x) => x.name.trim().toLowerCase()).toSet();
  var n = 2;
  var name = '${t.name} ($n)';
  while (names.contains(name.toLowerCase())) {
    n++;
    name = '${t.name} ($n)';
  }
  return SampleTemplate(
    id: newId,
    name: name,
    codePrefix: t.codePrefix,
    color: t.color,
    defaultStorageInstruction: t.defaultStorageInstruction,
    category: t.category,
    fields: t.fields,
  );
}
