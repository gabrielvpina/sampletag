import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../../domain/sample_code.dart';
import '../../domain/sample_code.dart' as sc show nextChildCode;
import '../db/database.dart';

/// Acesso às amostras no banco local.
class SampleRepository {
  SampleRepository(this._db);

  final AppDatabase _db;

  /// Observa todas as amostras, mais recentes primeiro.
  Stream<List<Sample>> watchAll() {
    final q = _db.select(_db.samples)
      ..orderBy([(t) => OrderingTerm.desc(t.collectedAt)]);
    return q.watch().map((rows) => rows.map(AppDatabase.sampleFromRow).toList());
  }

  Future<List<Sample>> getAll() async {
    final rows = await (_db.select(_db.samples)
          ..orderBy([(t) => OrderingTerm.desc(t.collectedAt)]))
        .get();
    return rows.map(AppDatabase.sampleFromRow).toList();
  }

  Stream<Sample?> watchById(String id) =>
      (_db.select(_db.samples)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : AppDatabase.sampleFromRow(r));

  Future<Sample?> getById(String id) async {
    final r = await (_db.select(_db.samples)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return r == null ? null : AppDatabase.sampleFromRow(r);
  }

  /// Busca pelo código legível (usado pelo leitor de QR). Ignora caixa.
  Future<Sample?> getByCode(String code) async {
    final r = await (_db.select(_db.samples)
          ..where((t) => t.sampleCode.lower().equals(code.trim().toLowerCase())))
        .getSingleOrNull();
    return r == null ? null : AppDatabase.sampleFromRow(r);
  }

  Future<bool> codeExists(String code, {String? exceptId}) async {
    final q = _db.select(_db.samples)
      ..where((t) => t.sampleCode.lower().equals(code.trim().toLowerCase()));
    if (exceptId != null) q.where((t) => t.id.equals(exceptId).not());
    return (await q.get()).isNotEmpty;
  }

  /// Gera o próximo código livre para o prefixo e data informados.
  Future<String> nextCode({
    required String pattern,
    required String prefix,
    required DateTime date,
    String collector = '',
  }) async {
    final codes = await (_db.selectOnly(_db.samples)
          ..addColumns([_db.samples.sampleCode]))
        .map((r) => r.read(_db.samples.sampleCode)!)
        .get();
    return nextSampleCode(
        existingCodes: codes, pattern: pattern, prefix: prefix, date: date, collector: collector);
  }

  /// Próximo código livre para uma amostra técnica derivada de [parentCode].
  Future<String> nextChildCode(String parentCode) async {
    final codes = await (_db.selectOnly(_db.samples)
          ..addColumns([_db.samples.sampleCode]))
        .map((r) => r.read(_db.samples.sampleCode)!)
        .get();
    return sc.nextChildCode(parentCode, codes);
  }

  /// Amostras técnicas derivadas de [parentId], na ordem do código.
  Stream<List<Sample>> watchChildren(String parentId) {
    final q = _db.select(_db.samples)
      ..where((t) => t.parentId.equals(parentId))
      ..orderBy([(t) => OrderingTerm.asc(t.sampleCode)]);
    return q.watch().map((rows) => rows.map(AppDatabase.sampleFromRow).toList());
  }

  /// Insere ou atualiza (pelo `id`).
  Future<void> upsert(Sample s) =>
      _db.into(_db.samples).insertOnConflictUpdate(AppDatabase.sampleToCompanion(s));

  Future<void> upsertAll(Iterable<Sample> samples) => _db.batch((b) {
        b.insertAllOnConflictUpdate(
            _db.samples, samples.map(AppDatabase.sampleToCompanion).toList());
      });

  Future<void> delete(String id) => deleteMany([id]);

  /// Exclui várias amostras de uma vez. As amostras técnicas derivadas
  /// delas são mantidas, apenas perdem o vínculo com a origem.
  Future<void> deleteMany(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.samples)..where((t) => t.parentId.isIn(list)))
          .write(const SamplesCompanion(parentId: Value(null)));
      await (_db.delete(_db.samples)..where((t) => t.id.isIn(list))).go();
    });
  }
}
