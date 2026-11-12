// Planejamento da importação de coleta de outro celular. Dart puro.
//
// Fluxo: o pacote recebido (ZIP de backup) é comparado com o banco local,
// cada amostra é classificada, o usuário revisa a prévia e escolhe o que
// fazer com conflitos; só então o plano é aplicado.

import 'models.dart';

/// Situação de uma amostra recebida em relação ao banco local.
enum ImportKind {
  /// Não existe aqui: será adicionada.
  added,

  /// Mesma amostra (mesmo id), versão recebida mais recente.
  updated,

  /// Mesma amostra, sem alterações.
  unchanged,

  /// Mesma amostra, mas a versão local é mais recente: mantém a local.
  olderThanLocal,

  /// Outra amostra (id diferente) com o mesmo código.
  codeConflict,

  /// Modelo de ficha ausente no pacote e no aparelho: não dá para importar.
  missingTemplate,
}

/// O que fazer com um conflito de código.
enum ConflictAction {
  rename('Renomear'),
  skip('Pular'),
  replace('Substituir');

  const ConflictAction(this.label);
  final String label;
}

class ImportItem {
  const ImportItem({required this.incoming, required this.kind, this.existing});

  /// Amostra recebida, já com o `templateId` local.
  final Sample incoming;
  final ImportKind kind;

  /// Amostra local relacionada (mesmo id ou mesmo código).
  final Sample? existing;
}

/// Quem gerou o pacote.
class ImportSource {
  const ImportSource({this.collectorName = '', this.collectorTag = '', this.project = '', this.createdAt});
  final String collectorName;
  final String collectorTag;
  final String project;
  final DateTime? createdAt;

  String get label {
    final who = [
      if (collectorName.isNotEmpty) collectorName,
      if (collectorTag.isNotEmpty) '($collectorTag)',
    ].join(' ');
    return who.isEmpty ? 'Origem não informada' : who;
  }
}

/// Resultado da resolução: o que gravar e o que apagar.
class ImportChanges {
  const ImportChanges({
    required this.upserts,
    required this.deleteIds,
    required this.templates,
    required this.renamed,
    required this.skipped,
  });

  final List<Sample> upserts;

  /// Amostras locais substituídas por uma recebida com o mesmo código.
  final List<String> deleteIds;
  final List<SampleTemplate> templates;

  /// Código original -> novo código, para amostras renomeadas.
  final Map<String, String> renamed;
  final int skipped;
}

class ImportPlan {
  ImportPlan._({
    required this.source,
    required this.items,
    required this.newTemplates,
    required this.templateIdMap,
    required this.localCodes,
  });

  final ImportSource source;
  final List<ImportItem> items;

  /// Modelos que não existem aqui (nem com o mesmo nome e prefixo).
  final List<SampleTemplate> newTemplates;

  /// id do modelo no pacote -> id local.
  final Map<String, String> templateIdMap;

  /// Códigos (minúsculos) que já existiam no aparelho.
  final Set<String> localCodes;

  int count(ImportKind k) => items.where((i) => i.kind == k).length;
  List<ImportItem> get conflicts => items.where((i) => i.kind == ImportKind.codeConflict).toList();

  /// Compara o pacote com o banco local.
  factory ImportPlan.build({
    required List<Sample> incomingSamples,
    required List<SampleTemplate> incomingTemplates,
    required List<Sample> localSamples,
    required List<SampleTemplate> localTemplates,
    ImportSource source = const ImportSource(),
  }) {
    // 1. Modelos: mesmo id, ou mesmo nome + prefixo, é o mesmo modelo.
    final localById = {for (final t in localTemplates) t.id: t};
    String key(SampleTemplate t) => '${t.name.trim().toLowerCase()}|${t.codePrefix.trim().toUpperCase()}';
    final localByKey = {for (final t in localTemplates) key(t): t};
    final idMap = <String, String>{};
    final newTemplates = <SampleTemplate>[];
    for (final t in incomingTemplates) {
      if (localById.containsKey(t.id)) {
        idMap[t.id] = t.id;
      } else if (localByKey.containsKey(key(t))) {
        idMap[t.id] = localByKey[key(t)]!.id;
      } else {
        idMap[t.id] = t.id;
        newTemplates.add(t);
      }
    }

    // 2. Amostras.
    final localById2 = {for (final s in localSamples) s.id: s};
    // Códigos ocupados (minúsculos) -> id. Inclui as recebidas já
    // processadas, para pegar repetições dentro do próprio pacote.
    final taken = {for (final s in localSamples) s.sampleCode.toLowerCase(): s.id};
    final localCodes = taken.keys.toSet();
    final items = <ImportItem>[];

    for (final raw in incomingSamples) {
      final tplId = idMap[raw.templateId] ?? (localById.containsKey(raw.templateId) ? raw.templateId : null);
      if (tplId == null) {
        items.add(ImportItem(incoming: raw, kind: ImportKind.missingTemplate));
        continue;
      }
      final s = raw.templateId == tplId ? raw : raw.copyWith(templateId: tplId);
      final codeKey = s.sampleCode.toLowerCase();
      final sameId = localById2[s.id];
      final codeOwner = taken[codeKey];

      if (codeOwner != null && codeOwner != s.id) {
        final other = localById2[codeOwner] ??
            incomingSamples.firstWhere((x) => x.id == codeOwner, orElse: () => s);
        items.add(ImportItem(incoming: s, kind: ImportKind.codeConflict, existing: other));
        continue;
      }
      if (sameId == null) {
        items.add(ImportItem(incoming: s, kind: ImportKind.added));
      } else if (s.updatedAt.isAfter(sameId.updatedAt)) {
        items.add(ImportItem(incoming: s, kind: ImportKind.updated, existing: sameId));
      } else if (s.updatedAt.isAtSameMomentAs(sameId.updatedAt)) {
        items.add(ImportItem(incoming: s, kind: ImportKind.unchanged, existing: sameId));
      } else {
        items.add(ImportItem(incoming: s, kind: ImportKind.olderThanLocal, existing: sameId));
      }
      taken[codeKey] = s.id;
    }

    return ImportPlan._(
      source: source,
      items: items,
      newTemplates: newTemplates,
      templateIdMap: idMap,
      localCodes: localCodes,
    );
  }

  /// Aplica as escolhas do usuário.
  ///
  /// [conflictAction] decide cada conflito de código; [updateExisting]
  /// controla se amostras já importadas antes são atualizadas.
  ImportChanges resolve({
    required ConflictAction Function(ImportItem item) conflictAction,
    bool updateExisting = true,
  }) {
    final upserts = <Sample>[];
    final deleteIds = <String>[];
    final renamed = <String, String>{};
    var skipped = 0;

    // Códigos que ficarão ocupados depois da importação.
    final taken = {...localCodes};
    for (final i in items) {
      if (i.kind == ImportKind.added || (i.kind == ImportKind.updated && updateExisting)) {
        taken.add(i.incoming.sampleCode.toLowerCase());
      }
    }

    for (final i in items) {
      switch (i.kind) {
        case ImportKind.added:
          upserts.add(i.incoming);
        case ImportKind.updated:
          if (updateExisting) {
            upserts.add(i.incoming);
          } else {
            skipped++;
          }
        case ImportKind.unchanged:
        case ImportKind.olderThanLocal:
        case ImportKind.missingTemplate:
          skipped++;
        case ImportKind.codeConflict:
          switch (conflictAction(i)) {
            case ConflictAction.skip:
              skipped++;
            case ConflictAction.rename:
              final code = uniqueCode(i.incoming.sampleCode, taken);
              taken.add(code.toLowerCase());
              renamed[i.incoming.sampleCode] = code;
              upserts.add(i.incoming.copyWith(sampleCode: code));
            case ConflictAction.replace:
              final local = i.existing;
              // Só substitui amostras locais; repetição dentro do pacote
              // é renomeada para não perder dados.
              if (local != null && localCodes.contains(local.sampleCode.toLowerCase()) && local.id != i.incoming.id) {
                deleteIds.add(local.id);
                upserts.add(i.incoming);
              } else {
                final code = uniqueCode(i.incoming.sampleCode, taken);
                taken.add(code.toLowerCase());
                renamed[i.incoming.sampleCode] = code;
                upserts.add(i.incoming.copyWith(sampleCode: code));
              }
          }
      }
    }

    // Modelos que não existiam aqui são criados (mesmo que nenhuma amostra
    // os use agora), para que futuras importações casem pelo id.
    return ImportChanges(
      upserts: upserts,
      deleteIds: deleteIds,
      templates: newTemplates,
      renamed: renamed,
      skipped: skipped,
    );
  }
}

/// Acrescenta -B, -C, … até o código ficar livre (comparação sem caixa).
String uniqueCode(String code, Set<String> takenLower) {
  const letters = 'BCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (final l in letters.split('')) {
    final c = '$code-$l';
    if (!takenLower.contains(c.toLowerCase())) return c;
  }
  var n = 2;
  while (takenLower.contains('$code-$n'.toLowerCase())) {
    n++;
  }
  return '$code-$n';
}
