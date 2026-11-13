// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codePrefixMeta = const VerificationMeta(
    'codePrefix',
  );
  @override
  late final GeneratedColumn<String> codePrefix = GeneratedColumn<String>(
    'code_prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultStorageInstructionMeta =
      const VerificationMeta('defaultStorageInstruction');
  @override
  late final GeneratedColumn<String> defaultStorageInstruction =
      GeneratedColumn<String>(
        'default_storage_instruction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldsJsonMeta = const VerificationMeta(
    'fieldsJson',
  );
  @override
  late final GeneratedColumn<String> fieldsJson = GeneratedColumn<String>(
    'fields_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    codePrefix,
    color,
    defaultStorageInstruction,
    category,
    fieldsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code_prefix')) {
      context.handle(
        _codePrefixMeta,
        codePrefix.isAcceptableOrUnknown(data['code_prefix']!, _codePrefixMeta),
      );
    } else if (isInserting) {
      context.missing(_codePrefixMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('default_storage_instruction')) {
      context.handle(
        _defaultStorageInstructionMeta,
        defaultStorageInstruction.isAcceptableOrUnknown(
          data['default_storage_instruction']!,
          _defaultStorageInstructionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('fields_json')) {
      context.handle(
        _fieldsJsonMeta,
        fieldsJson.isAcceptableOrUnknown(data['fields_json']!, _fieldsJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      codePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_prefix'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      defaultStorageInstruction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_storage_instruction'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      fieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  final String id;
  final String name;
  final String codePrefix;
  final int color;
  final String defaultStorageInstruction;
  final String category;

  /// Lista de [TemplateField] serializada em JSON.
  final String fieldsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TemplateRow({
    required this.id,
    required this.name,
    required this.codePrefix,
    required this.color,
    required this.defaultStorageInstruction,
    required this.category,
    required this.fieldsJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['code_prefix'] = Variable<String>(codePrefix);
    map['color'] = Variable<int>(color);
    map['default_storage_instruction'] = Variable<String>(
      defaultStorageInstruction,
    );
    map['category'] = Variable<String>(category);
    map['fields_json'] = Variable<String>(fieldsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      name: Value(name),
      codePrefix: Value(codePrefix),
      color: Value(color),
      defaultStorageInstruction: Value(defaultStorageInstruction),
      category: Value(category),
      fieldsJson: Value(fieldsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      codePrefix: serializer.fromJson<String>(json['codePrefix']),
      color: serializer.fromJson<int>(json['color']),
      defaultStorageInstruction: serializer.fromJson<String>(
        json['defaultStorageInstruction'],
      ),
      category: serializer.fromJson<String>(json['category']),
      fieldsJson: serializer.fromJson<String>(json['fieldsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'codePrefix': serializer.toJson<String>(codePrefix),
      'color': serializer.toJson<int>(color),
      'defaultStorageInstruction': serializer.toJson<String>(
        defaultStorageInstruction,
      ),
      'category': serializer.toJson<String>(category),
      'fieldsJson': serializer.toJson<String>(fieldsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TemplateRow copyWith({
    String? id,
    String? name,
    String? codePrefix,
    int? color,
    String? defaultStorageInstruction,
    String? category,
    String? fieldsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TemplateRow(
    id: id ?? this.id,
    name: name ?? this.name,
    codePrefix: codePrefix ?? this.codePrefix,
    color: color ?? this.color,
    defaultStorageInstruction:
        defaultStorageInstruction ?? this.defaultStorageInstruction,
    category: category ?? this.category,
    fieldsJson: fieldsJson ?? this.fieldsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TemplateRow copyWithCompanion(TemplatesCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      codePrefix: data.codePrefix.present
          ? data.codePrefix.value
          : this.codePrefix,
      color: data.color.present ? data.color.value : this.color,
      defaultStorageInstruction: data.defaultStorageInstruction.present
          ? data.defaultStorageInstruction.value
          : this.defaultStorageInstruction,
      category: data.category.present ? data.category.value : this.category,
      fieldsJson: data.fieldsJson.present
          ? data.fieldsJson.value
          : this.fieldsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('codePrefix: $codePrefix, ')
          ..write('color: $color, ')
          ..write('defaultStorageInstruction: $defaultStorageInstruction, ')
          ..write('category: $category, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    codePrefix,
    color,
    defaultStorageInstruction,
    category,
    fieldsJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.codePrefix == this.codePrefix &&
          other.color == this.color &&
          other.defaultStorageInstruction == this.defaultStorageInstruction &&
          other.category == this.category &&
          other.fieldsJson == this.fieldsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TemplatesCompanion extends UpdateCompanion<TemplateRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> codePrefix;
  final Value<int> color;
  final Value<String> defaultStorageInstruction;
  final Value<String> category;
  final Value<String> fieldsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.codePrefix = const Value.absent(),
    this.color = const Value.absent(),
    this.defaultStorageInstruction = const Value.absent(),
    this.category = const Value.absent(),
    this.fieldsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String name,
    required String codePrefix,
    required int color,
    this.defaultStorageInstruction = const Value.absent(),
    required String category,
    this.fieldsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       codePrefix = Value(codePrefix),
       color = Value(color),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TemplateRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? codePrefix,
    Expression<int>? color,
    Expression<String>? defaultStorageInstruction,
    Expression<String>? category,
    Expression<String>? fieldsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (codePrefix != null) 'code_prefix': codePrefix,
      if (color != null) 'color': color,
      if (defaultStorageInstruction != null)
        'default_storage_instruction': defaultStorageInstruction,
      if (category != null) 'category': category,
      if (fieldsJson != null) 'fields_json': fieldsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? codePrefix,
    Value<int>? color,
    Value<String>? defaultStorageInstruction,
    Value<String>? category,
    Value<String>? fieldsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      codePrefix: codePrefix ?? this.codePrefix,
      color: color ?? this.color,
      defaultStorageInstruction:
          defaultStorageInstruction ?? this.defaultStorageInstruction,
      category: category ?? this.category,
      fieldsJson: fieldsJson ?? this.fieldsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (codePrefix.present) {
      map['code_prefix'] = Variable<String>(codePrefix.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (defaultStorageInstruction.present) {
      map['default_storage_instruction'] = Variable<String>(
        defaultStorageInstruction.value,
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (fieldsJson.present) {
      map['fields_json'] = Variable<String>(fieldsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('codePrefix: $codePrefix, ')
          ..write('color: $color, ')
          ..write('defaultStorageInstruction: $defaultStorageInstruction, ')
          ..write('category: $category, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SamplesTable extends Samples with TableInfo<$SamplesTable, SampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleCodeMeta = const VerificationMeta(
    'sampleCode',
  );
  @override
  late final GeneratedColumn<String> sampleCode = GeneratedColumn<String>(
    'sample_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id)',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectedAtMeta = const VerificationMeta(
    'collectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> collectedAt = GeneratedColumn<DateTime>(
    'collected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectorNameMeta = const VerificationMeta(
    'collectorName',
  );
  @override
  late final GeneratedColumn<String> collectorName = GeneratedColumn<String>(
    'collector_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _collectorContactMeta = const VerificationMeta(
    'collectorContact',
  );
  @override
  late final GeneratedColumn<String> collectorContact = GeneratedColumn<String>(
    'collector_contact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cloneGenotypeMeta = const VerificationMeta(
    'cloneGenotype',
  );
  @override
  late final GeneratedColumn<String> cloneGenotype = GeneratedColumn<String>(
    'clone_genotype',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originPropertyMeta = const VerificationMeta(
    'originProperty',
  );
  @override
  late final GeneratedColumn<String> originProperty = GeneratedColumn<String>(
    'origin_property',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _municipalityMeta = const VerificationMeta(
    'municipality',
  );
  @override
  late final GeneratedColumn<String> municipality = GeneratedColumn<String>(
    'municipality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsAccuracyMetersMeta = const VerificationMeta(
    'gpsAccuracyMeters',
  );
  @override
  late final GeneratedColumn<double> gpsAccuracyMeters =
      GeneratedColumn<double>(
        'gps_accuracy_meters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _photosJsonMeta = const VerificationMeta(
    'photosJson',
  );
  @override
  late final GeneratedColumn<String> photosJson = GeneratedColumn<String>(
    'photos_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _storageInstructionMeta =
      const VerificationMeta('storageInstruction');
  @override
  late final GeneratedColumn<String> storageInstruction =
      GeneratedColumn<String>(
        'storage_instruction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _customFieldsJsonMeta = const VerificationMeta(
    'customFieldsJson',
  );
  @override
  late final GeneratedColumn<String> customFieldsJson = GeneratedColumn<String>(
    'custom_fields_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sampleCode,
    templateId,
    category,
    collectedAt,
    collectorName,
    collectorContact,
    cloneGenotype,
    originProperty,
    municipality,
    state,
    latitude,
    longitude,
    altitude,
    gpsAccuracyMeters,
    photosJson,
    notes,
    storageInstruction,
    customFieldsJson,
    parentId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<SampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sample_code')) {
      context.handle(
        _sampleCodeMeta,
        sampleCode.isAcceptableOrUnknown(data['sample_code']!, _sampleCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_sampleCodeMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('collected_at')) {
      context.handle(
        _collectedAtMeta,
        collectedAt.isAcceptableOrUnknown(
          data['collected_at']!,
          _collectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectedAtMeta);
    }
    if (data.containsKey('collector_name')) {
      context.handle(
        _collectorNameMeta,
        collectorName.isAcceptableOrUnknown(
          data['collector_name']!,
          _collectorNameMeta,
        ),
      );
    }
    if (data.containsKey('collector_contact')) {
      context.handle(
        _collectorContactMeta,
        collectorContact.isAcceptableOrUnknown(
          data['collector_contact']!,
          _collectorContactMeta,
        ),
      );
    }
    if (data.containsKey('clone_genotype')) {
      context.handle(
        _cloneGenotypeMeta,
        cloneGenotype.isAcceptableOrUnknown(
          data['clone_genotype']!,
          _cloneGenotypeMeta,
        ),
      );
    }
    if (data.containsKey('origin_property')) {
      context.handle(
        _originPropertyMeta,
        originProperty.isAcceptableOrUnknown(
          data['origin_property']!,
          _originPropertyMeta,
        ),
      );
    }
    if (data.containsKey('municipality')) {
      context.handle(
        _municipalityMeta,
        municipality.isAcceptableOrUnknown(
          data['municipality']!,
          _municipalityMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('gps_accuracy_meters')) {
      context.handle(
        _gpsAccuracyMetersMeta,
        gpsAccuracyMeters.isAcceptableOrUnknown(
          data['gps_accuracy_meters']!,
          _gpsAccuracyMetersMeta,
        ),
      );
    }
    if (data.containsKey('photos_json')) {
      context.handle(
        _photosJsonMeta,
        photosJson.isAcceptableOrUnknown(data['photos_json']!, _photosJsonMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('storage_instruction')) {
      context.handle(
        _storageInstructionMeta,
        storageInstruction.isAcceptableOrUnknown(
          data['storage_instruction']!,
          _storageInstructionMeta,
        ),
      );
    }
    if (data.containsKey('custom_fields_json')) {
      context.handle(
        _customFieldsJsonMeta,
        customFieldsJson.isAcceptableOrUnknown(
          data['custom_fields_json']!,
          _customFieldsJsonMeta,
        ),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sampleCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_code'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      collectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}collected_at'],
      )!,
      collectorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collector_name'],
      )!,
      collectorContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collector_contact'],
      )!,
      cloneGenotype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clone_genotype'],
      )!,
      originProperty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_property'],
      )!,
      municipality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      gpsAccuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_accuracy_meters'],
      ),
      photosJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photos_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      storageInstruction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_instruction'],
      )!,
      customFieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_fields_json'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SamplesTable createAlias(String alias) {
    return $SamplesTable(attachedDatabase, alias);
  }
}

class SampleRow extends DataClass implements Insertable<SampleRow> {
  final String id;
  final String sampleCode;
  final String templateId;
  final String category;
  final DateTime collectedAt;
  final String collectorName;
  final String collectorContact;
  final String cloneGenotype;
  final String originProperty;
  final String municipality;
  final String state;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? gpsAccuracyMeters;

  /// Lista de nomes de arquivo (relativos) em JSON.
  final String photosJson;
  final String notes;
  final String storageInstruction;
  final String customFieldsJson;

  /// Amostra de origem (amostra técnica derivada de outra). Sem chave
  /// estrangeira: a origem pode ser excluída ou ainda não ter sido importada.
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SampleRow({
    required this.id,
    required this.sampleCode,
    required this.templateId,
    required this.category,
    required this.collectedAt,
    required this.collectorName,
    required this.collectorContact,
    required this.cloneGenotype,
    required this.originProperty,
    required this.municipality,
    required this.state,
    this.latitude,
    this.longitude,
    this.altitude,
    this.gpsAccuracyMeters,
    required this.photosJson,
    required this.notes,
    required this.storageInstruction,
    required this.customFieldsJson,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sample_code'] = Variable<String>(sampleCode);
    map['template_id'] = Variable<String>(templateId);
    map['category'] = Variable<String>(category);
    map['collected_at'] = Variable<DateTime>(collectedAt);
    map['collector_name'] = Variable<String>(collectorName);
    map['collector_contact'] = Variable<String>(collectorContact);
    map['clone_genotype'] = Variable<String>(cloneGenotype);
    map['origin_property'] = Variable<String>(originProperty);
    map['municipality'] = Variable<String>(municipality);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || gpsAccuracyMeters != null) {
      map['gps_accuracy_meters'] = Variable<double>(gpsAccuracyMeters);
    }
    map['photos_json'] = Variable<String>(photosJson);
    map['notes'] = Variable<String>(notes);
    map['storage_instruction'] = Variable<String>(storageInstruction);
    map['custom_fields_json'] = Variable<String>(customFieldsJson);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SamplesCompanion toCompanion(bool nullToAbsent) {
    return SamplesCompanion(
      id: Value(id),
      sampleCode: Value(sampleCode),
      templateId: Value(templateId),
      category: Value(category),
      collectedAt: Value(collectedAt),
      collectorName: Value(collectorName),
      collectorContact: Value(collectorContact),
      cloneGenotype: Value(cloneGenotype),
      originProperty: Value(originProperty),
      municipality: Value(municipality),
      state: Value(state),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      gpsAccuracyMeters: gpsAccuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsAccuracyMeters),
      photosJson: Value(photosJson),
      notes: Value(notes),
      storageInstruction: Value(storageInstruction),
      customFieldsJson: Value(customFieldsJson),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SampleRow(
      id: serializer.fromJson<String>(json['id']),
      sampleCode: serializer.fromJson<String>(json['sampleCode']),
      templateId: serializer.fromJson<String>(json['templateId']),
      category: serializer.fromJson<String>(json['category']),
      collectedAt: serializer.fromJson<DateTime>(json['collectedAt']),
      collectorName: serializer.fromJson<String>(json['collectorName']),
      collectorContact: serializer.fromJson<String>(json['collectorContact']),
      cloneGenotype: serializer.fromJson<String>(json['cloneGenotype']),
      originProperty: serializer.fromJson<String>(json['originProperty']),
      municipality: serializer.fromJson<String>(json['municipality']),
      state: serializer.fromJson<String>(json['state']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      gpsAccuracyMeters: serializer.fromJson<double?>(
        json['gpsAccuracyMeters'],
      ),
      photosJson: serializer.fromJson<String>(json['photosJson']),
      notes: serializer.fromJson<String>(json['notes']),
      storageInstruction: serializer.fromJson<String>(
        json['storageInstruction'],
      ),
      customFieldsJson: serializer.fromJson<String>(json['customFieldsJson']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sampleCode': serializer.toJson<String>(sampleCode),
      'templateId': serializer.toJson<String>(templateId),
      'category': serializer.toJson<String>(category),
      'collectedAt': serializer.toJson<DateTime>(collectedAt),
      'collectorName': serializer.toJson<String>(collectorName),
      'collectorContact': serializer.toJson<String>(collectorContact),
      'cloneGenotype': serializer.toJson<String>(cloneGenotype),
      'originProperty': serializer.toJson<String>(originProperty),
      'municipality': serializer.toJson<String>(municipality),
      'state': serializer.toJson<String>(state),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'altitude': serializer.toJson<double?>(altitude),
      'gpsAccuracyMeters': serializer.toJson<double?>(gpsAccuracyMeters),
      'photosJson': serializer.toJson<String>(photosJson),
      'notes': serializer.toJson<String>(notes),
      'storageInstruction': serializer.toJson<String>(storageInstruction),
      'customFieldsJson': serializer.toJson<String>(customFieldsJson),
      'parentId': serializer.toJson<String?>(parentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SampleRow copyWith({
    String? id,
    String? sampleCode,
    String? templateId,
    String? category,
    DateTime? collectedAt,
    String? collectorName,
    String? collectorContact,
    String? cloneGenotype,
    String? originProperty,
    String? municipality,
    String? state,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<double?> altitude = const Value.absent(),
    Value<double?> gpsAccuracyMeters = const Value.absent(),
    String? photosJson,
    String? notes,
    String? storageInstruction,
    String? customFieldsJson,
    Value<String?> parentId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SampleRow(
    id: id ?? this.id,
    sampleCode: sampleCode ?? this.sampleCode,
    templateId: templateId ?? this.templateId,
    category: category ?? this.category,
    collectedAt: collectedAt ?? this.collectedAt,
    collectorName: collectorName ?? this.collectorName,
    collectorContact: collectorContact ?? this.collectorContact,
    cloneGenotype: cloneGenotype ?? this.cloneGenotype,
    originProperty: originProperty ?? this.originProperty,
    municipality: municipality ?? this.municipality,
    state: state ?? this.state,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    altitude: altitude.present ? altitude.value : this.altitude,
    gpsAccuracyMeters: gpsAccuracyMeters.present
        ? gpsAccuracyMeters.value
        : this.gpsAccuracyMeters,
    photosJson: photosJson ?? this.photosJson,
    notes: notes ?? this.notes,
    storageInstruction: storageInstruction ?? this.storageInstruction,
    customFieldsJson: customFieldsJson ?? this.customFieldsJson,
    parentId: parentId.present ? parentId.value : this.parentId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SampleRow copyWithCompanion(SamplesCompanion data) {
    return SampleRow(
      id: data.id.present ? data.id.value : this.id,
      sampleCode: data.sampleCode.present
          ? data.sampleCode.value
          : this.sampleCode,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      category: data.category.present ? data.category.value : this.category,
      collectedAt: data.collectedAt.present
          ? data.collectedAt.value
          : this.collectedAt,
      collectorName: data.collectorName.present
          ? data.collectorName.value
          : this.collectorName,
      collectorContact: data.collectorContact.present
          ? data.collectorContact.value
          : this.collectorContact,
      cloneGenotype: data.cloneGenotype.present
          ? data.cloneGenotype.value
          : this.cloneGenotype,
      originProperty: data.originProperty.present
          ? data.originProperty.value
          : this.originProperty,
      municipality: data.municipality.present
          ? data.municipality.value
          : this.municipality,
      state: data.state.present ? data.state.value : this.state,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      gpsAccuracyMeters: data.gpsAccuracyMeters.present
          ? data.gpsAccuracyMeters.value
          : this.gpsAccuracyMeters,
      photosJson: data.photosJson.present
          ? data.photosJson.value
          : this.photosJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      storageInstruction: data.storageInstruction.present
          ? data.storageInstruction.value
          : this.storageInstruction,
      customFieldsJson: data.customFieldsJson.present
          ? data.customFieldsJson.value
          : this.customFieldsJson,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SampleRow(')
          ..write('id: $id, ')
          ..write('sampleCode: $sampleCode, ')
          ..write('templateId: $templateId, ')
          ..write('category: $category, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('collectorName: $collectorName, ')
          ..write('collectorContact: $collectorContact, ')
          ..write('cloneGenotype: $cloneGenotype, ')
          ..write('originProperty: $originProperty, ')
          ..write('municipality: $municipality, ')
          ..write('state: $state, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('gpsAccuracyMeters: $gpsAccuracyMeters, ')
          ..write('photosJson: $photosJson, ')
          ..write('notes: $notes, ')
          ..write('storageInstruction: $storageInstruction, ')
          ..write('customFieldsJson: $customFieldsJson, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sampleCode,
    templateId,
    category,
    collectedAt,
    collectorName,
    collectorContact,
    cloneGenotype,
    originProperty,
    municipality,
    state,
    latitude,
    longitude,
    altitude,
    gpsAccuracyMeters,
    photosJson,
    notes,
    storageInstruction,
    customFieldsJson,
    parentId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SampleRow &&
          other.id == this.id &&
          other.sampleCode == this.sampleCode &&
          other.templateId == this.templateId &&
          other.category == this.category &&
          other.collectedAt == this.collectedAt &&
          other.collectorName == this.collectorName &&
          other.collectorContact == this.collectorContact &&
          other.cloneGenotype == this.cloneGenotype &&
          other.originProperty == this.originProperty &&
          other.municipality == this.municipality &&
          other.state == this.state &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitude == this.altitude &&
          other.gpsAccuracyMeters == this.gpsAccuracyMeters &&
          other.photosJson == this.photosJson &&
          other.notes == this.notes &&
          other.storageInstruction == this.storageInstruction &&
          other.customFieldsJson == this.customFieldsJson &&
          other.parentId == this.parentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SamplesCompanion extends UpdateCompanion<SampleRow> {
  final Value<String> id;
  final Value<String> sampleCode;
  final Value<String> templateId;
  final Value<String> category;
  final Value<DateTime> collectedAt;
  final Value<String> collectorName;
  final Value<String> collectorContact;
  final Value<String> cloneGenotype;
  final Value<String> originProperty;
  final Value<String> municipality;
  final Value<String> state;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> altitude;
  final Value<double?> gpsAccuracyMeters;
  final Value<String> photosJson;
  final Value<String> notes;
  final Value<String> storageInstruction;
  final Value<String> customFieldsJson;
  final Value<String?> parentId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SamplesCompanion({
    this.id = const Value.absent(),
    this.sampleCode = const Value.absent(),
    this.templateId = const Value.absent(),
    this.category = const Value.absent(),
    this.collectedAt = const Value.absent(),
    this.collectorName = const Value.absent(),
    this.collectorContact = const Value.absent(),
    this.cloneGenotype = const Value.absent(),
    this.originProperty = const Value.absent(),
    this.municipality = const Value.absent(),
    this.state = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.gpsAccuracyMeters = const Value.absent(),
    this.photosJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.storageInstruction = const Value.absent(),
    this.customFieldsJson = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SamplesCompanion.insert({
    required String id,
    required String sampleCode,
    required String templateId,
    required String category,
    required DateTime collectedAt,
    this.collectorName = const Value.absent(),
    this.collectorContact = const Value.absent(),
    this.cloneGenotype = const Value.absent(),
    this.originProperty = const Value.absent(),
    this.municipality = const Value.absent(),
    this.state = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.gpsAccuracyMeters = const Value.absent(),
    this.photosJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.storageInstruction = const Value.absent(),
    this.customFieldsJson = const Value.absent(),
    this.parentId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sampleCode = Value(sampleCode),
       templateId = Value(templateId),
       category = Value(category),
       collectedAt = Value(collectedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SampleRow> custom({
    Expression<String>? id,
    Expression<String>? sampleCode,
    Expression<String>? templateId,
    Expression<String>? category,
    Expression<DateTime>? collectedAt,
    Expression<String>? collectorName,
    Expression<String>? collectorContact,
    Expression<String>? cloneGenotype,
    Expression<String>? originProperty,
    Expression<String>? municipality,
    Expression<String>? state,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitude,
    Expression<double>? gpsAccuracyMeters,
    Expression<String>? photosJson,
    Expression<String>? notes,
    Expression<String>? storageInstruction,
    Expression<String>? customFieldsJson,
    Expression<String>? parentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sampleCode != null) 'sample_code': sampleCode,
      if (templateId != null) 'template_id': templateId,
      if (category != null) 'category': category,
      if (collectedAt != null) 'collected_at': collectedAt,
      if (collectorName != null) 'collector_name': collectorName,
      if (collectorContact != null) 'collector_contact': collectorContact,
      if (cloneGenotype != null) 'clone_genotype': cloneGenotype,
      if (originProperty != null) 'origin_property': originProperty,
      if (municipality != null) 'municipality': municipality,
      if (state != null) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (gpsAccuracyMeters != null) 'gps_accuracy_meters': gpsAccuracyMeters,
      if (photosJson != null) 'photos_json': photosJson,
      if (notes != null) 'notes': notes,
      if (storageInstruction != null) 'storage_instruction': storageInstruction,
      if (customFieldsJson != null) 'custom_fields_json': customFieldsJson,
      if (parentId != null) 'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SamplesCompanion copyWith({
    Value<String>? id,
    Value<String>? sampleCode,
    Value<String>? templateId,
    Value<String>? category,
    Value<DateTime>? collectedAt,
    Value<String>? collectorName,
    Value<String>? collectorContact,
    Value<String>? cloneGenotype,
    Value<String>? originProperty,
    Value<String>? municipality,
    Value<String>? state,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<double?>? altitude,
    Value<double?>? gpsAccuracyMeters,
    Value<String>? photosJson,
    Value<String>? notes,
    Value<String>? storageInstruction,
    Value<String>? customFieldsJson,
    Value<String?>? parentId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SamplesCompanion(
      id: id ?? this.id,
      sampleCode: sampleCode ?? this.sampleCode,
      templateId: templateId ?? this.templateId,
      category: category ?? this.category,
      collectedAt: collectedAt ?? this.collectedAt,
      collectorName: collectorName ?? this.collectorName,
      collectorContact: collectorContact ?? this.collectorContact,
      cloneGenotype: cloneGenotype ?? this.cloneGenotype,
      originProperty: originProperty ?? this.originProperty,
      municipality: municipality ?? this.municipality,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      photosJson: photosJson ?? this.photosJson,
      notes: notes ?? this.notes,
      storageInstruction: storageInstruction ?? this.storageInstruction,
      customFieldsJson: customFieldsJson ?? this.customFieldsJson,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sampleCode.present) {
      map['sample_code'] = Variable<String>(sampleCode.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (collectedAt.present) {
      map['collected_at'] = Variable<DateTime>(collectedAt.value);
    }
    if (collectorName.present) {
      map['collector_name'] = Variable<String>(collectorName.value);
    }
    if (collectorContact.present) {
      map['collector_contact'] = Variable<String>(collectorContact.value);
    }
    if (cloneGenotype.present) {
      map['clone_genotype'] = Variable<String>(cloneGenotype.value);
    }
    if (originProperty.present) {
      map['origin_property'] = Variable<String>(originProperty.value);
    }
    if (municipality.present) {
      map['municipality'] = Variable<String>(municipality.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (gpsAccuracyMeters.present) {
      map['gps_accuracy_meters'] = Variable<double>(gpsAccuracyMeters.value);
    }
    if (photosJson.present) {
      map['photos_json'] = Variable<String>(photosJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (storageInstruction.present) {
      map['storage_instruction'] = Variable<String>(storageInstruction.value);
    }
    if (customFieldsJson.present) {
      map['custom_fields_json'] = Variable<String>(customFieldsJson.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SamplesCompanion(')
          ..write('id: $id, ')
          ..write('sampleCode: $sampleCode, ')
          ..write('templateId: $templateId, ')
          ..write('category: $category, ')
          ..write('collectedAt: $collectedAt, ')
          ..write('collectorName: $collectorName, ')
          ..write('collectorContact: $collectorContact, ')
          ..write('cloneGenotype: $cloneGenotype, ')
          ..write('originProperty: $originProperty, ')
          ..write('municipality: $municipality, ')
          ..write('state: $state, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('gpsAccuracyMeters: $gpsAccuracyMeters, ')
          ..write('photosJson: $photosJson, ')
          ..write('notes: $notes, ')
          ..write('storageInstruction: $storageInstruction, ')
          ..write('customFieldsJson: $customFieldsJson, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValueRow extends DataClass implements Insertable<KeyValueRow> {
  final String key;
  final String value;
  const KeyValueRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueRow copyWith({String? key, String? value}) =>
      KeyValueRow(key: key ?? this.key, value: value ?? this.value);
  KeyValueRow copyWithCompanion(KeyValuesCompanion data) {
    return KeyValueRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueRow &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValueRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValueRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $SamplesTable samples = $SamplesTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    templates,
    samples,
    keyValues,
  ];
}

typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String name,
  required String codePrefix,
  required int color,
  Value<String> defaultStorageInstruction,
  required String category,
  Value<String> fieldsJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> codePrefix,
  Value<int> color,
  Value<String> defaultStorageInstruction,
  Value<String> category,
  Value<String> fieldsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow> {
  $$TemplatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SamplesTable, List<SampleRow>> _samplesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.samples,
    aliasName: 'templates__id__samples__template_id',
  );

  $$SamplesTableProcessedTableManager get samplesRefs {
    final manager = $$SamplesTableTableManager(
      $_db,
      $_db.samples,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_samplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codePrefix => $composableBuilder(
    column: $table.codePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultStorageInstruction => $composableBuilder(
    column: $table.defaultStorageInstruction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> samplesRefs(
    Expression<bool> Function($$SamplesTableFilterComposer f) f,
  ) {
    final $$SamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableFilterComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codePrefix => $composableBuilder(
    column: $table.codePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultStorageInstruction => $composableBuilder(
    column: $table.defaultStorageInstruction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get codePrefix => $composableBuilder(
    column: $table.codePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get defaultStorageInstruction => $composableBuilder(
    column: $table.defaultStorageInstruction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> samplesRefs<T extends Object>(
    Expression<T> Function($$SamplesTableAnnotationComposer a) f,
  ) {
    final $$SamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          TemplateRow,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (TemplateRow, $$TemplatesTableReferences),
          TemplateRow,
          PrefetchHooks Function({bool samplesRefs})
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> codePrefix = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String> defaultStorageInstruction = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> fieldsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                name: name,
                codePrefix: codePrefix,
                color: color,
                defaultStorageInstruction: defaultStorageInstruction,
                category: category,
                fieldsJson: fieldsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String codePrefix,
                required int color,
                Value<String> defaultStorageInstruction = const Value.absent(),
                required String category,
                Value<String> fieldsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                name: name,
                codePrefix: codePrefix,
                color: color,
                defaultStorageInstruction: defaultStorageInstruction,
                category: category,
                fieldsJson: fieldsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplatesTable, TemplateRow>(table),
                  $$TemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({samplesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (samplesRefs) db.samples],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (samplesRefs)
                    await $_getPrefetchedDataByColumns<
                      TemplateRow,
                      $TemplatesTable,
                      SampleRow,
                      $SamplesTable
                    >(
                      currentTable: table,
                      referencedTable: $$TemplatesTableReferences
                          ._samplesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TemplatesTableReferences(db, table, p0).samplesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'template_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      TemplateRow,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (TemplateRow, $$TemplatesTableReferences),
      TemplateRow,
      PrefetchHooks Function({bool samplesRefs})
    >;
typedef $$SamplesTableCreateCompanionBuilder = SamplesCompanion Function({
  required String id,
  required String sampleCode,
  required String templateId,
  required String category,
  required DateTime collectedAt,
  Value<String> collectorName,
  Value<String> collectorContact,
  Value<String> cloneGenotype,
  Value<String> originProperty,
  Value<String> municipality,
  Value<String> state,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> altitude,
  Value<double?> gpsAccuracyMeters,
  Value<String> photosJson,
  Value<String> notes,
  Value<String> storageInstruction,
  Value<String> customFieldsJson,
  Value<String?> parentId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SamplesTableUpdateCompanionBuilder = SamplesCompanion Function({
  Value<String> id,
  Value<String> sampleCode,
  Value<String> templateId,
  Value<String> category,
  Value<DateTime> collectedAt,
  Value<String> collectorName,
  Value<String> collectorContact,
  Value<String> cloneGenotype,
  Value<String> originProperty,
  Value<String> municipality,
  Value<String> state,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> altitude,
  Value<double?> gpsAccuracyMeters,
  Value<String> photosJson,
  Value<String> notes,
  Value<String> storageInstruction,
  Value<String> customFieldsJson,
  Value<String?> parentId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$SamplesTableReferences
    extends BaseReferences<_$AppDatabase, $SamplesTable, SampleRow> {
  $$SamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.templates.createAlias('samples__template_id__templates__id');

  $$TemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$TemplatesTableTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SamplesTableFilterComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sampleCode => $composableBuilder(
    column: $table.sampleCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectorName => $composableBuilder(
    column: $table.collectorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectorContact => $composableBuilder(
    column: $table.collectorContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloneGenotype => $composableBuilder(
    column: $table.cloneGenotype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originProperty => $composableBuilder(
    column: $table.originProperty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipality => $composableBuilder(
    column: $table.municipality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsAccuracyMeters => $composableBuilder(
    column: $table.gpsAccuracyMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photosJson => $composableBuilder(
    column: $table.photosJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageInstruction => $composableBuilder(
    column: $table.storageInstruction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplatesTableFilterComposer get templateId {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleCode => $composableBuilder(
    column: $table.sampleCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectorName => $composableBuilder(
    column: $table.collectorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectorContact => $composableBuilder(
    column: $table.collectorContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloneGenotype => $composableBuilder(
    column: $table.cloneGenotype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originProperty => $composableBuilder(
    column: $table.originProperty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipality => $composableBuilder(
    column: $table.municipality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsAccuracyMeters => $composableBuilder(
    column: $table.gpsAccuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photosJson => $composableBuilder(
    column: $table.photosJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageInstruction => $composableBuilder(
    column: $table.storageInstruction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplatesTableOrderingComposer get templateId {
    final $$TemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sampleCode => $composableBuilder(
    column: $table.sampleCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get collectedAt => $composableBuilder(
    column: $table.collectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collectorName => $composableBuilder(
    column: $table.collectorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collectorContact => $composableBuilder(
    column: $table.collectorContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloneGenotype => $composableBuilder(
    column: $table.cloneGenotype,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originProperty => $composableBuilder(
    column: $table.originProperty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get municipality => $composableBuilder(
    column: $table.municipality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get gpsAccuracyMeters => $composableBuilder(
    column: $table.gpsAccuracyMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photosJson => $composableBuilder(
    column: $table.photosJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get storageInstruction => $composableBuilder(
    column: $table.storageInstruction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TemplatesTableAnnotationComposer get templateId {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SamplesTable,
          SampleRow,
          $$SamplesTableFilterComposer,
          $$SamplesTableOrderingComposer,
          $$SamplesTableAnnotationComposer,
          $$SamplesTableCreateCompanionBuilder,
          $$SamplesTableUpdateCompanionBuilder,
          (SampleRow, $$SamplesTableReferences),
          SampleRow,
          PrefetchHooks Function({bool templateId})
        > {
  $$SamplesTableTableManager(_$AppDatabase db, $SamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sampleCode = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> collectedAt = const Value.absent(),
                Value<String> collectorName = const Value.absent(),
                Value<String> collectorContact = const Value.absent(),
                Value<String> cloneGenotype = const Value.absent(),
                Value<String> originProperty = const Value.absent(),
                Value<String> municipality = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> gpsAccuracyMeters = const Value.absent(),
                Value<String> photosJson = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> storageInstruction = const Value.absent(),
                Value<String> customFieldsJson = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SamplesCompanion(
                id: id,
                sampleCode: sampleCode,
                templateId: templateId,
                category: category,
                collectedAt: collectedAt,
                collectorName: collectorName,
                collectorContact: collectorContact,
                cloneGenotype: cloneGenotype,
                originProperty: originProperty,
                municipality: municipality,
                state: state,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                gpsAccuracyMeters: gpsAccuracyMeters,
                photosJson: photosJson,
                notes: notes,
                storageInstruction: storageInstruction,
                customFieldsJson: customFieldsJson,
                parentId: parentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sampleCode,
                required String templateId,
                required String category,
                required DateTime collectedAt,
                Value<String> collectorName = const Value.absent(),
                Value<String> collectorContact = const Value.absent(),
                Value<String> cloneGenotype = const Value.absent(),
                Value<String> originProperty = const Value.absent(),
                Value<String> municipality = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> gpsAccuracyMeters = const Value.absent(),
                Value<String> photosJson = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> storageInstruction = const Value.absent(),
                Value<String> customFieldsJson = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SamplesCompanion.insert(
                id: id,
                sampleCode: sampleCode,
                templateId: templateId,
                category: category,
                collectedAt: collectedAt,
                collectorName: collectorName,
                collectorContact: collectorContact,
                cloneGenotype: cloneGenotype,
                originProperty: originProperty,
                municipality: municipality,
                state: state,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                gpsAccuracyMeters: gpsAccuracyMeters,
                photosJson: photosJson,
                notes: notes,
                storageInstruction: storageInstruction,
                customFieldsJson: customFieldsJson,
                parentId: parentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SamplesTable, SampleRow>(table),
                  $$SamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (templateId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.templateId,
                        referencedTable: $$SamplesTableReferences
                            ._templateIdTable(db),
                        referencedColumn: $$SamplesTableReferences
                            ._templateIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SamplesTable,
      SampleRow,
      $$SamplesTableFilterComposer,
      $$SamplesTableOrderingComposer,
      $$SamplesTableAnnotationComposer,
      $$SamplesTableCreateCompanionBuilder,
      $$SamplesTableUpdateCompanionBuilder,
      (SampleRow, $$SamplesTableReferences),
      SampleRow,
      PrefetchHooks Function({bool templateId})
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValueRow,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (
            KeyValueRow,
            BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>,
          ),
          KeyValueRow,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValueRow>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValueRow,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (
        KeyValueRow,
        BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>,
      ),
      KeyValueRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$SamplesTableTableManager get samples =>
      $$SamplesTableTableManager(_db, _db.samples);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
}
