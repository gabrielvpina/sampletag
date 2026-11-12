import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../../domain/sample_code.dart';
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
  }) async {
    final codes = await (_db.selectOnly(_db.samples)
          ..addColumns([_db.samples.sampleCode]))
        .map((r) => r.read(_db.samples.sampleCode)!)
        .get();
    return nextSampleCode(
        existingCodes: codes, pattern: pattern, prefix: prefix, date: date);
  }

  /// Insere ou atualiza (pelo `id`).
  Future<void> upsert(Sample s) =>
      _db.into(_db.samples).insertOnConflictUpdate(AppDatabase.sampleToCompanion(s));

  Future<void> upsertAll(Iterable<Sample> samples) => _db.batch((b) {
        b.insertAllOnConflictUpdate(
            _db.samples, samples.map(AppDatabase.sampleToCompanion).toList());
      });

  Future<void> delete(String id) =>
      (_db.delete(_db.samples)..where((t) => t.id.equals(id))).go();
}
