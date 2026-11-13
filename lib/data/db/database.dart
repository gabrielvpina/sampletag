// Banco local (drift/SQLite).
//
// Para regenerar o código após alterar tabelas:
//   dart run build_runner build

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/models.dart';
import '../../domain/seed_data.dart';

part 'database.g.dart';

@DataClassName('TemplateRow')
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get codePrefix => text()();
  IntColumn get color => integer()();
  TextColumn get defaultStorageInstruction => text().withDefault(const Constant(''))();
  TextColumn get category => text()();

  /// Lista de [TemplateField] serializada em JSON.
  TextColumn get fieldsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SampleRow')
class Samples extends Table {
  TextColumn get id => text()();
  TextColumn get sampleCode => text().unique()();
  TextColumn get templateId => text().references(Templates, #id)();
  TextColumn get category => text()();
  DateTimeColumn get collectedAt => dateTime()();
  TextColumn get collectorName => text().withDefault(const Constant(''))();
  TextColumn get collectorContact => text().withDefault(const Constant(''))();
  TextColumn get cloneGenotype => text().withDefault(const Constant(''))();
  TextColumn get originProperty => text().withDefault(const Constant(''))();
  TextColumn get municipality => text().withDefault(const Constant(''))();
  TextColumn get state => text().withDefault(const Constant(''))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get altitude => real().nullable()();
  RealColumn get gpsAccuracyMeters => real().nullable()();

  /// Lista de nomes de arquivo (relativos) em JSON.
  TextColumn get photosJson => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get storageInstruction => text().withDefault(const Constant(''))();
  TextColumn get customFieldsJson => text().withDefault(const Constant('{}'))();

  /// Amostra de origem (amostra técnica derivada de outra). Sem chave
  /// estrangeira: a origem pode ser excluída ou ainda não ter sido importada.
  TextColumn get parentId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Armazenamento chave/valor para configurações e rascunhos.
@DataClassName('KeyValueRow')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Assinatura de um passo de migração: recebe o [Migrator] e o banco.
typedef MigrationStep = Future<void> Function(Migrator m, AppDatabase db);

@DriftDatabase(tables: [Templates, Samples, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static const dbName = 'sampletag';

  /// Versão atual do esquema. Ao alterar tabelas: incremente aqui e adicione
  /// um passo em [migrations] com a chave = versão de origem.
  @override
  int get schemaVersion => 2;

  /// Migrações versionadas: `migrations[n]` leva o esquema da versão n para n+1.
  /// Exemplo futuro:
  ///   2: (m, db) => m.addColumn(db.samples, db.samples.someNewColumn),
  static final Map<int, MigrationStep> migrations = {
    // v2: amostras técnicas derivadas de uma amostra de origem.
    1: (m, db) => m.addColumn(db.samples, db.samples.parentId),
  };

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(templates).insert(templateToCompanion(cacauTemplate));
        },
        onUpgrade: (m, from, to) async {
          for (var v = from; v < to; v++) {
            final step = migrations[v];
            if (step == null) {
              throw StateError('Migração ausente da versão $v para ${v + 1}');
            }
            await step(m, this);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(name: dbName);

  // ---------------------------------------------------------------------------
  // Conversões linha <-> domínio
  // ---------------------------------------------------------------------------

  static TemplatesCompanion templateToCompanion(SampleTemplate t, {DateTime? now}) {
    final ts = now ?? DateTime.now();
    return TemplatesCompanion.insert(
      id: t.id,
      name: t.name,
      codePrefix: t.codePrefix,
      color: t.color,
      defaultStorageInstruction: Value(t.defaultStorageInstruction),
      category: t.category.code,
      fieldsJson: Value(jsonEncode(t.fields.map((f) => f.toJson()).toList())),
      createdAt: ts,
      updatedAt: ts,
    );
  }

  static SampleTemplate templateFromRow(TemplateRow r) {
    List<TemplateField> fields;
    try {
      fields = (jsonDecode(r.fieldsJson) as List)
          .map((e) => TemplateField.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    } on Object {
      fields = const [];
    }
    return SampleTemplate(
      id: r.id,
      name: r.name,
      codePrefix: r.codePrefix,
      color: r.color,
      defaultStorageInstruction: r.defaultStorageInstruction,
      category: SampleCategory.fromCode(r.category),
      fields: fields,
    );
  }

  static SamplesCompanion sampleToCompanion(Sample s) => SamplesCompanion.insert(
        id: s.id,
        sampleCode: s.sampleCode,
        templateId: s.templateId,
        category: s.category.code,
        collectedAt: s.collectedAt,
        collectorName: Value(s.collectorName),
        collectorContact: Value(s.collectorContact),
        cloneGenotype: Value(s.cloneGenotype),
        originProperty: Value(s.originProperty),
        municipality: Value(s.municipality),
        state: Value(s.state),
        latitude: Value(s.latitude),
        longitude: Value(s.longitude),
        altitude: Value(s.altitude),
        gpsAccuracyMeters: Value(s.gpsAccuracyMeters),
        photosJson: Value(jsonEncode(s.photos)),
        notes: Value(s.notes),
        storageInstruction: Value(s.storageInstruction),
        customFieldsJson: Value(jsonEncode(s.customFields)),
        parentId: Value(s.parentId),
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      );

  static Sample sampleFromRow(SampleRow r) {
    List<String> photos;
    try {
      photos = (jsonDecode(r.photosJson) as List).cast<String>();
    } on Object {
      photos = const [];
    }
    return Sample(
      id: r.id,
      sampleCode: r.sampleCode,
      templateId: r.templateId,
      category: SampleCategory.fromCode(r.category),
      collectedAt: r.collectedAt,
      collectorName: r.collectorName,
      collectorContact: r.collectorContact,
      cloneGenotype: r.cloneGenotype,
      originProperty: r.originProperty,
      municipality: r.municipality,
      state: r.state,
      latitude: r.latitude,
      longitude: r.longitude,
      altitude: r.altitude,
      gpsAccuracyMeters: r.gpsAccuracyMeters,
      photos: photos,
      notes: r.notes,
      storageInstruction: r.storageInstruction,
      customFields: Sample.decodeCustomFields(r.customFieldsJson),
      parentId: r.parentId,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
