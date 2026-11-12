// Provedores Riverpod: injeção de dependências e estado compartilhado.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db/database.dart';
import 'data/repositories/sample_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/template_repository.dart';
import 'domain/models.dart';
import 'domain/sample_filter.dart';
import 'services/export/export_service.dart';
import 'services/geocoding_service.dart';
import 'services/location_service.dart';
import 'services/photo_service.dart';

/// Banco. Nos testes, sobrescreva com `AppDatabase(NativeDatabase.memory())`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final sampleRepoProvider = Provider((ref) => SampleRepository(ref.watch(databaseProvider)));
final templateRepoProvider = Provider((ref) => TemplateRepository(ref.watch(databaseProvider)));
final settingsRepoProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

final photoServiceProvider = Provider((ref) => PhotoService());
final locationServiceProvider = Provider((ref) => LocationService());
final geocodingServiceProvider = Provider((ref) => GeocodingService());
final exportServiceProvider = Provider((ref) => ExportService(
      samples: ref.watch(sampleRepoProvider),
      templates: ref.watch(templateRepoProvider),
      settings: ref.watch(settingsRepoProvider),
      photos: ref.watch(photoServiceProvider),
      db: ref.watch(databaseProvider),
    ));

final samplesProvider = StreamProvider<List<Sample>>((ref) => ref.watch(sampleRepoProvider).watchAll());

final templatesProvider =
    StreamProvider<List<SampleTemplate>>((ref) => ref.watch(templateRepoProvider).watchAll());

final templatesByIdProvider = Provider<Map<String, SampleTemplate>>((ref) => {
      for (final t in ref.watch(templatesProvider).value ?? const <SampleTemplate>[]) t.id: t,
    });

final settingsProvider = StreamProvider<AppSettings>((ref) => ref.watch(settingsRepoProvider).watch());

final sampleByIdProvider =
    StreamProvider.family<Sample?, String>((ref, id) => ref.watch(sampleRepoProvider).watchById(id));

/// Filtro da lista de amostras (compartilhado com a tela de exportação, que
/// oferece "exportar só as filtradas").
class SampleFilterNotifier extends Notifier<SampleFilter> {
  @override
  SampleFilter build() => const SampleFilter();

  void update(SampleFilter f) => state = f;
  void setQuery(String q) => state = state.copyWith(query: q);
  void clear() => state = state.cleared();
}

final sampleFilterProvider =
    NotifierProvider<SampleFilterNotifier, SampleFilter>(SampleFilterNotifier.new);

final filteredSamplesProvider = Provider<AsyncValue<List<Sample>>>((ref) {
  final filter = ref.watch(sampleFilterProvider);
  final templates = ref.watch(templatesByIdProvider);
  return ref.watch(samplesProvider).whenData((list) => filter.apply(list, templates));
});
