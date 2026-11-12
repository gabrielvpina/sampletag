import 'dart:convert';

import '../../domain/models.dart';
import '../db/database.dart';

/// Configurações e rascunhos, guardados na tabela chave/valor.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _settingsPrefix = 'settings.';
  static const _draftPrefix = 'draft.';

  Stream<AppSettings> watch() => _db.select(_db.keyValues).watch().map(_toSettings);

  Future<AppSettings> get() async => _toSettings(await _db.select(_db.keyValues).get());

  AppSettings _toSettings(List<KeyValueRow> rows) => AppSettings.fromMap({
        for (final r in rows)
          if (r.key.startsWith(_settingsPrefix)) r.key.substring(_settingsPrefix.length): r.value,
      });

  Future<void> save(AppSettings s) => _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.keyValues, [
          for (final e in s.toMap().entries)
            KeyValuesCompanion.insert(key: '$_settingsPrefix${e.key}', value: e.value),
        ]);
      });

  // ---- Rascunhos do formulário (salvos automaticamente) ----

  /// [slot] é `new` para nova amostra ou o id da amostra em edição.
  Future<void> saveDraft(String slot, Map<String, Object?> data) =>
      _db.into(_db.keyValues).insertOnConflictUpdate(
            KeyValuesCompanion.insert(key: '$_draftPrefix$slot', value: jsonEncode(data)),
          );

  Future<Map<String, Object?>?> loadDraft(String slot) async {
    final r = await (_db.select(_db.keyValues)..where((t) => t.key.equals('$_draftPrefix$slot')))
        .getSingleOrNull();
    if (r == null) return null;
    try {
      return (jsonDecode(r.value) as Map).cast<String, Object?>();
    } on Object {
      return null;
    }
  }

  Future<void> clearDraft(String slot) =>
      (_db.delete(_db.keyValues)..where((t) => t.key.equals('$_draftPrefix$slot'))).go();
}
