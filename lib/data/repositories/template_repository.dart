import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db/database.dart';

/// Acesso aos modelos de ficha.
class TemplateRepository {
  TemplateRepository(this._db);

  final AppDatabase _db;

  Stream<List<SampleTemplate>> watchAll() =>
      (_db.select(_db.templates)..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch()
          .map((rows) => rows.map(AppDatabase.templateFromRow).toList());

  Future<List<SampleTemplate>> getAll() async =>
      (await (_db.select(_db.templates)..orderBy([(t) => OrderingTerm.asc(t.name)])).get())
          .map(AppDatabase.templateFromRow)
          .toList();

  Future<SampleTemplate?> getById(String id) async {
    final r = await (_db.select(_db.templates)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return r == null ? null : AppDatabase.templateFromRow(r);
  }

  /// Insere ou atualiza. Preserva `createdAt` em atualizações.
  Future<void> upsert(SampleTemplate t) async {
    final existing = await (_db.select(_db.templates)..where((x) => x.id.equals(t.id)))
        .getSingleOrNull();
    final now = DateTime.now();
    final companion = AppDatabase.templateToCompanion(t, now: now);
    await _db.into(_db.templates).insertOnConflictUpdate(
          existing == null ? companion : companion.copyWith(createdAt: Value(existing.createdAt)),
        );
  }

  Future<void> upsertAll(Iterable<SampleTemplate> list) async {
    for (final t in list) {
      await upsert(t);
    }
  }

  /// Quantas amostras usam o modelo (impede exclusão de modelo em uso).
  Future<int> usageCount(String templateId) async {
    final count = _db.samples.id.count();
    final q = _db.selectOnly(_db.samples)
      ..addColumns([count])
      ..where(_db.samples.templateId.equals(templateId));
    return (await q.map((r) => r.read(count)).getSingle()) ?? 0;
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.templates)..where((t) => t.id.equals(id))).go();
}
