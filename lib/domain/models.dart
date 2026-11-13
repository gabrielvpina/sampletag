// Modelos de domínio do SampleTag.
//
// Este arquivo é Dart puro (sem Flutter), para poder ser usado tanto pelo app
// quanto por ferramentas de linha de comando (ex.: tool/generate_demo_report.dart)
// e testes unitários.

import 'dart:convert';

import 'sample_code.dart';

/// Categoria da amostra.
enum SampleCategory {
  biological('biologica', 'Biológica'),
  technical('tecnica', 'Técnica');

  const SampleCategory(this.code, this.label);

  /// Valor persistido no banco/JSON.
  final String code;

  /// Rótulo exibido ao usuário.
  final String label;

  static SampleCategory fromCode(String? code) => SampleCategory.values
      .firstWhere((c) => c.code == code, orElse: () => SampleCategory.biological);
}

/// Tipos de campo extra suportados nos modelos de ficha.
enum FieldType {
  text('texto', 'Texto'),
  number('numero', 'Número'),
  list('lista', 'Lista'),
  date('data', 'Data');

  const FieldType(this.code, this.label);
  final String code;
  final String label;

  static FieldType fromCode(String? code) =>
      FieldType.values.firstWhere((t) => t.code == code, orElse: () => FieldType.text);
}

/// Definição de um campo extra de um modelo de ficha.
class TemplateField {
  const TemplateField({
    required this.key,
    required this.label,
    this.type = FieldType.text,
    this.required = false,
    this.options = const [],
  });

  /// Chave usada em [Sample.customFields]. Estável mesmo que o rótulo mude.
  final String key;
  final String label;
  final FieldType type;
  final bool required;

  /// Opções quando [type] é [FieldType.list].
  final List<String> options;

  TemplateField copyWith({
    String? key,
    String? label,
    FieldType? type,
    bool? required,
    List<String>? options,
  }) =>
      TemplateField(
        key: key ?? this.key,
        label: label ?? this.label,
        type: type ?? this.type,
        required: required ?? this.required,
        options: options ?? this.options,
      );

  Map<String, Object?> toJson() => {
        'key': key,
        'label': label,
        'type': type.code,
        'required': required,
        if (options.isNotEmpty) 'options': options,
      };

  factory TemplateField.fromJson(Map<String, Object?> json) => TemplateField(
        key: json['key'] as String,
        label: json['label'] as String? ?? json['key'] as String,
        type: FieldType.fromCode(json['type'] as String?),
        required: json['required'] as bool? ?? false,
        options: (json['options'] as List?)?.cast<String>() ?? const [],
      );
}

/// Modelo de ficha (ex.: "Cacau").
class SampleTemplate {
  const SampleTemplate({
    required this.id,
    required this.name,
    required this.codePrefix,
    required this.color,
    required this.defaultStorageInstruction,
    required this.category,
    this.fields = const [],
  });

  final String id;
  final String name;

  /// Prefixo usado no código legível (ex.: `CAC`).
  final String codePrefix;

  /// Cor ARGB (0xAARRGGBB), usada no app, nas etiquetas e no relatório.
  final int color;
  final String defaultStorageInstruction;
  final SampleCategory category;
  final List<TemplateField> fields;

  /// Cor no formato CSS `#RRGGBB`.
  String get colorHex =>
      '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  SampleTemplate copyWith({
    String? name,
    String? codePrefix,
    int? color,
    String? defaultStorageInstruction,
    SampleCategory? category,
    List<TemplateField>? fields,
  }) =>
      SampleTemplate(
        id: id,
        name: name ?? this.name,
        codePrefix: codePrefix ?? this.codePrefix,
        color: color ?? this.color,
        defaultStorageInstruction:
            defaultStorageInstruction ?? this.defaultStorageInstruction,
        category: category ?? this.category,
        fields: fields ?? this.fields,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'codePrefix': codePrefix,
        'color': colorHex,
        'defaultStorageInstruction': defaultStorageInstruction,
        'category': category.code,
        'fields': fields.map((f) => f.toJson()).toList(),
      };

  factory SampleTemplate.fromJson(Map<String, Object?> json) => SampleTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        codePrefix: json['codePrefix'] as String,
        color: parseColor(json['color']),
        defaultStorageInstruction: json['defaultStorageInstruction'] as String? ?? '',
        category: SampleCategory.fromCode(json['category'] as String?),
        fields: ((json['fields'] as List?) ?? const [])
            .map((e) => TemplateField.fromJson((e as Map).cast<String, Object?>()))
            .toList(),
      );

  /// Aceita `#RRGGBB` ou inteiro ARGB.
  static int parseColor(Object? value) {
    if (value is int) return value;
    if (value is String) {
      final hex = value.replaceFirst('#', '');
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) return hex.length <= 6 ? 0xFF000000 | parsed : parsed;
    }
    return 0xFF3D5C40;
  }
}

/// Amostra de campo.
class Sample {
  const Sample({
    required this.id,
    required this.sampleCode,
    required this.templateId,
    required this.category,
    required this.collectedAt,
    this.collectorName = '',
    this.collectorContact = '',
    this.cloneGenotype = '',
    this.originProperty = '',
    this.municipality = '',
    this.state = '',
    this.latitude,
    this.longitude,
    this.altitude,
    this.gpsAccuracyMeters,
    this.photos = const [],
    this.notes = '',
    this.storageInstruction = '',
    this.customFields = const {},
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sampleCode;
  final String templateId;
  final SampleCategory category;
  final DateTime collectedAt;
  final String collectorName;
  final String collectorContact;
  final String cloneGenotype;
  final String originProperty;
  final String municipality;

  /// UF (sigla de 2 letras).
  final String state;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? gpsAccuracyMeters;

  /// Nomes de arquivo das fotos, relativos à pasta de fotos do app.
  /// Guardamos caminhos relativos porque no iOS o caminho absoluto do
  /// container muda entre instalações/restaurações.
  final List<String> photos;
  final String notes;
  final String storageInstruction;

  /// Valores dos campos extras do modelo, indexados por [TemplateField.key].
  final Map<String, Object?> customFields;

  /// Amostra de origem (ex.: a amostra biológica da qual esta amostra
  /// técnica foi derivada). `null` para amostras independentes.
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isChild => parentId != null;

  bool get hasLocation => latitude != null && longitude != null;

  /// "Município/UF" pronto para exibição.
  String get place {
    if (municipality.isEmpty) return state;
    if (state.isEmpty) return municipality;
    return '$municipality/$state';
  }

  Sample copyWith({
    String? sampleCode,
    String? templateId,
    SampleCategory? category,
    DateTime? collectedAt,
    String? collectorName,
    String? collectorContact,
    String? cloneGenotype,
    String? originProperty,
    String? municipality,
    String? state,
    double? latitude,
    double? longitude,
    double? altitude,
    double? gpsAccuracyMeters,
    List<String>? photos,
    String? notes,
    String? storageInstruction,
    Map<String, Object?>? customFields,
    String? Function()? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Sample(
        id: id,
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
        photos: photos ?? this.photos,
        notes: notes ?? this.notes,
        storageInstruction: storageInstruction ?? this.storageInstruction,
        customFields: customFields ?? this.customFields,
        parentId: parentId != null ? parentId() : this.parentId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'sampleCode': sampleCode,
        'templateId': templateId,
        'category': category.code,
        'collectedAt': collectedAt.toIso8601String(),
        'collectorName': collectorName,
        'collectorContact': collectorContact,
        'cloneGenotype': cloneGenotype,
        'originProperty': originProperty,
        'municipality': municipality,
        'state': state,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'gpsAccuracyMeters': gpsAccuracyMeters,
        'photos': photos,
        'notes': notes,
        'storageInstruction': storageInstruction,
        'customFields': customFields,
        if (parentId != null) 'parentId': parentId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Sample.fromJson(Map<String, Object?> json) {
    double? d(Object? v) => (v as num?)?.toDouble();
    return Sample(
      id: json['id'] as String,
      sampleCode: json['sampleCode'] as String,
      templateId: json['templateId'] as String,
      category: SampleCategory.fromCode(json['category'] as String?),
      collectedAt: DateTime.parse(json['collectedAt'] as String),
      collectorName: json['collectorName'] as String? ?? '',
      collectorContact: json['collectorContact'] as String? ?? '',
      cloneGenotype: json['cloneGenotype'] as String? ?? '',
      originProperty: json['originProperty'] as String? ?? '',
      municipality: json['municipality'] as String? ?? '',
      state: json['state'] as String? ?? '',
      latitude: d(json['latitude']),
      longitude: d(json['longitude']),
      altitude: d(json['altitude']),
      gpsAccuracyMeters: d(json['gpsAccuracyMeters']),
      photos: (json['photos'] as List?)?.cast<String>() ?? const [],
      notes: json['notes'] as String? ?? '',
      storageInstruction: json['storageInstruction'] as String? ?? '',
      customFields: (json['customFields'] as Map?)?.cast<String, Object?>() ?? const {},
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Decodifica o JSON de campos extras salvo no banco, tolerando lixo.
  static Map<String, Object?> decodeCustomFields(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final v = jsonDecode(raw);
      return v is Map ? v.cast<String, Object?>() : const {};
    } on FormatException {
      return const {};
    }
  }
}

/// Código da amostra de origem de [s], procurado em [codesById]
/// (id -> código). Vazio se não houver origem ou ela não estiver no mapa.
String parentCodeOf(Sample s, Map<String, String> codesById) =>
    s.parentId == null ? '' : codesById[s.parentId] ?? '';

/// Mapa id -> código das amostras.
Map<String, String> codesByIdOf(Iterable<Sample> samples) => {for (final s in samples) s.id: s.sampleCode};

/// Configurações do app.
class AppSettings {
  const AppSettings({
    this.collectorName = '',
    this.collectorContact = '',
    this.project = '',
    this.idPattern = defaultIdPattern,
    this.collectorCode = '',
    this.themeMode = 'system',
    this.mapStates = const {},
    this.municipalBoundaries = true,
  });

  /// Padrão do código legível. Tokens: `{PREFIXO}`, `{COLETOR}`, `{AAAA}`,
  /// `{AA}`, `{MM}`, `{DD}`, `{SEQ}` (4 dígitos) ou `{SEQn}` (n dígitos).
  /// `{COLETOR}` garante que celulares diferentes não gerem o mesmo código.
  static const defaultIdPattern = '{PREFIXO}-{COLETOR}-{AAAA}-{SEQ4}';

  final String collectorName;
  final String collectorContact;

  /// Projeto/expedição atual.
  final String project;
  final String idPattern;

  /// Código curto do coletor/aparelho usado em `{COLETOR}` (ex.: AS).
  final String collectorCode;

  /// Valor efetivo de `{COLETOR}`: o código configurado ou, se vazio, as
  /// iniciais do nome do coletor.
  String get collectorTag =>
      collectorCode.isNotEmpty ? normalizeCollectorCode(collectorCode) : collectorInitials(collectorName);

  /// O padrão usa `{COLETOR}`, mas ainda não há código nem nome.
  bool get needsCollectorCode => idPattern.contains('{COLETOR}') && collectorTag.isEmpty;

  /// 'system' | 'light' | 'dark'.
  final String themeMode;

  /// País da coleta. Por enquanto só há limites do Brasil.
  static const country = 'Brasil';

  /// UFs escolhidas para o mapa base, além das que aparecem nas amostras.
  final Set<String> mapStates;

  /// Mostrar limites municipais (IBGE) das UFs em destaque.
  final bool municipalBoundaries;

  AppSettings copyWith({
    String? collectorName,
    String? collectorContact,
    String? project,
    String? idPattern,
    String? collectorCode,
    String? themeMode,
    Set<String>? mapStates,
    bool? municipalBoundaries,
  }) =>
      AppSettings(
        collectorName: collectorName ?? this.collectorName,
        collectorContact: collectorContact ?? this.collectorContact,
        project: project ?? this.project,
        idPattern: idPattern ?? this.idPattern,
        collectorCode: collectorCode ?? this.collectorCode,
        themeMode: themeMode ?? this.themeMode,
        mapStates: mapStates ?? this.mapStates,
        municipalBoundaries: municipalBoundaries ?? this.municipalBoundaries,
      );

  Map<String, String> toMap() => {
        'collectorName': collectorName,
        'collectorContact': collectorContact,
        'project': project,
        'idPattern': idPattern,
        'collectorCode': collectorCode,
        'themeMode': themeMode,
        'mapStates': (mapStates.toList()..sort()).join(','),
        'municipalBoundaries': municipalBoundaries ? '1' : '0',
      };

  factory AppSettings.fromMap(Map<String, String> m) => AppSettings(
        collectorName: m['collectorName'] ?? '',
        collectorContact: m['collectorContact'] ?? '',
        project: m['project'] ?? '',
        idPattern: (m['idPattern']?.isNotEmpty ?? false) ? m['idPattern']! : defaultIdPattern,
        collectorCode: m['collectorCode'] ?? '',
        themeMode: m['themeMode'] ?? 'system',
        mapStates: {
          for (final u in (m['mapStates'] ?? '').split(','))
            if (u.trim().isNotEmpty) u.trim().toUpperCase(),
        },
        municipalBoundaries: m['municipalBoundaries'] != '0',
      );
}
