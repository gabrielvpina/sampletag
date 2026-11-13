import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/sample_code.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/location_service.dart';

/// Criação e edição de amostra.
///
/// O estado do formulário é salvo como rascunho a cada alteração (com
/// atraso de 600 ms), para não se perder se o app for fechado no campo.
class SampleFormScreen extends ConsumerStatefulWidget {
  const SampleFormScreen({super.key, this.existing, this.parent});

  /// Amostra em edição; `null` para nova.
  final Sample? existing;

  /// Nova amostra técnica derivada desta amostra (ex.: DNA extraído de uma
  /// folha). Herda modelo, local, coletor e campos; o código vira `ORIGEM-01`.
  final Sample? parent;

  @override
  ConsumerState<SampleFormScreen> createState() => _SampleFormScreenState();
}

class _SampleFormScreenState extends ConsumerState<SampleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _collector = TextEditingController();
  final _contact = TextEditingController();
  final _clone = TextEditingController();
  final _origin = TextEditingController();
  final _city = TextEditingController();
  final _uf = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _notes = TextEditingController();
  final _storage = TextEditingController();
  final Map<String, TextEditingController> _customText = {};

  SampleTemplate? _template;
  SampleCategory _category = SampleCategory.biological;
  DateTime _collectedAt = DateTime.now();
  double? _altitude;
  double? _accuracy;
  List<String> _photos = [];
  final Map<String, Object?> _custom = {};

  /// Fotos adicionadas nesta sessão (apagadas se o usuário descartar).
  final Set<String> _newPhotos = {};
  bool _codeEdited = false;
  bool _ready = false;
  bool _dirty = false;
  bool _saving = false;
  Timer? _draftTimer;

  /// Amostra de origem (para amostras técnicas derivadas).
  String? _parentId;
  String? _parentCode;

  // GPS automático: começa ao abrir uma amostra nova e vai refinando a
  // posição até atingir boa precisão, esgotar o tempo ou o usuário digitar
  // as coordenadas.
  StreamSubscription<Position>? _gpsSub;
  Timer? _gpsTimer;
  bool _gpsActive = false;
  String? _gpsError;
  (String, Future<void> Function())? _gpsErrorAction;
  bool _geocoded = false;
  static const _gpsMaxWait = Duration(seconds: 90);

  bool get _isEdit => widget.existing != null;
  String get _draftSlot => widget.existing?.id ?? (widget.parent != null ? 'child-${widget.parent!.id}' : 'new');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _stopGps();
    for (final c in [_code, _collector, _contact, _clone, _origin, _city, _uf, _lat, _lon, _notes, _storage, ..._customText.values]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Inicialização e rascunho
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    final templates = await ref.read(templateRepoProvider).getAll();
    final settings = await ref.read(settingsRepoProvider).get();
    final e = widget.existing;
    final parent = widget.parent;
    if (e != null) {
      _loadFromSample(e, templates);
      if (e.parentId != null) {
        _parentId = e.parentId;
        _parentCode = (await ref.read(sampleRepoProvider).getById(e.parentId!))?.sampleCode;
      }
    } else if (parent != null) {
      _loadFromSample(parent, templates);
      _parentId = parent.id;
      _parentCode = parent.sampleCode;
      _code.clear();
      _codeEdited = false;
      _category = SampleCategory.technical;
      _collectedAt = DateTime.now();
      _photos = [];
      _notes.clear();
      _storage.text = _template?.defaultStorageInstruction ?? '';
    } else {
      _collector.text = settings.collectorName;
      _contact.text = settings.collectorContact;
      if (templates.length == 1) _applyTemplate(templates.first, generateCode: false);
    }

    // Rascunho pendente?
    final draft = await ref.read(settingsRepoProvider).loadDraft(_draftSlot);
    if (draft != null && mounted) {
      final restore = await confirm(
        context,
        title: 'Rascunho encontrado',
        message: 'Há um rascunho não salvo${_isEdit ? ' desta amostra' : ''}. Deseja restaurá-lo?',
        confirmLabel: 'Restaurar',
      );
      if (restore) {
        _loadFromDraft(draft, templates);
      } else {
        await ref.read(settingsRepoProvider).clearDraft(_draftSlot);
      }
    }
    if (!_isEdit && parent == null && settings.needsCollectorCode && mounted) await _askCollectorCode(settings);
    if (!_isEdit && _template != null && _code.text.isEmpty) await _generateCode();
    if (!_isEdit) {
      // Android pode matar o app enquanto a câmera está aberta.
      try {
        final lost = await ref.read(photoServiceProvider).recoverLost();
        if (lost.isNotEmpty) {
          _photos.addAll(lost);
          _newPhotos.addAll(lost);
        }
      } on Object {
        // Sem dados perdidos ou plataforma sem suporte.
      }
    }
    if (mounted) setState(() => _ready = true);
    // Amostra nova sem coordenadas: busca a localização sozinha.
    if (!_isEdit && mounted && _lat.text.trim().isEmpty) unawaited(_startGps());
  }

  void _loadFromSample(Sample s, List<SampleTemplate> templates) {
    _template = templates.where((t) => t.id == s.templateId).firstOrNull;
    _code.text = s.sampleCode;
    _codeEdited = true;
    _category = s.category;
    _collectedAt = s.collectedAt;
    _collector.text = s.collectorName;
    _contact.text = s.collectorContact;
    _clone.text = s.cloneGenotype;
    _origin.text = s.originProperty;
    _city.text = s.municipality;
    _uf.text = s.state;
    _lat.text = fmtCoord(s.latitude);
    _lon.text = fmtCoord(s.longitude);
    _altitude = s.altitude;
    _accuracy = s.gpsAccuracyMeters;
    _photos = [...s.photos];
    _notes.text = s.notes;
    _storage.text = s.storageInstruction;
    _custom
      ..clear()
      ..addAll(s.customFields);
    _syncCustomControllers();
  }

  Map<String, Object?> _toDraft() => {
        'templateId': _template?.id,
        'code': _code.text,
        'codeEdited': _codeEdited,
        'category': _category.code,
        'collectedAt': _collectedAt.toIso8601String(),
        'collector': _collector.text,
        'contact': _contact.text,
        'clone': _clone.text,
        'origin': _origin.text,
        'city': _city.text,
        'uf': _uf.text,
        'lat': _lat.text,
        'lon': _lon.text,
        'alt': _altitude,
        'acc': _accuracy,
        'photos': _photos,
        'newPhotos': _newPhotos.toList(),
        'notes': _notes.text,
        'storage': _storage.text,
        'custom': _custom,
        'parentId': _parentId,
      };

  void _loadFromDraft(Map<String, Object?> d, List<SampleTemplate> templates) {
    String s(String k) => d[k] as String? ?? '';
    _template = templates.where((t) => t.id == d['templateId']).firstOrNull ?? _template;
    _code.text = s('code');
    _codeEdited = d['codeEdited'] as bool? ?? false;
    _category = SampleCategory.fromCode(d['category'] as String?);
    _collectedAt = DateTime.tryParse(s('collectedAt')) ?? _collectedAt;
    _collector.text = s('collector');
    _contact.text = s('contact');
    _clone.text = s('clone');
    _origin.text = s('origin');
    _city.text = s('city');
    _uf.text = s('uf');
    _lat.text = s('lat');
    _lon.text = s('lon');
    _altitude = (d['alt'] as num?)?.toDouble();
    _accuracy = (d['acc'] as num?)?.toDouble();
    _photos = (d['photos'] as List?)?.cast<String>() ?? [];
    _newPhotos.addAll((d['newPhotos'] as List?)?.cast<String>() ?? const []);
    _notes.text = s('notes');
    _storage.text = s('storage');
    _parentId = d['parentId'] as String? ?? _parentId;
    _custom
      ..clear()
      ..addAll((d['custom'] as Map?)?.cast<String, Object?>() ?? const {});
    _syncCustomControllers();
    _dirty = true;
  }

  void _syncCustomControllers() {
    for (final f in _template?.fields ?? const <TemplateField>[]) {
      if (f.type == FieldType.text || f.type == FieldType.number) {
        final c = _customText.putIfAbsent(f.key, TextEditingController.new);
        c.text = fmtCustomValue(_custom[f.key]).replaceAll(',', f.type == FieldType.number ? '.' : ',');
      }
    }
  }

  /// Marca o formulário como alterado e agenda o salvamento do rascunho.
  void _changed() {
    _dirty = true;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 600), () {
      ref.read(settingsRepoProvider).saveDraft(_draftSlot, _toDraft());
    });
  }

  void _applyTemplate(SampleTemplate t, {bool generateCode = true}) {
    setState(() {
      _template = t;
      _category = t.category;
      if (_storage.text.isEmpty || _storage.text == _previousDefaultStorage) {
        _storage.text = t.defaultStorageInstruction;
      }
      _previousDefaultStorage = t.defaultStorageInstruction;
      _syncCustomControllers();
    });
    if (generateCode && !_codeEdited) _generateCode();
    _changed();
  }

  String? _previousDefaultStorage;

  Future<void> _generateCode() async {
    final t = _template;
    if (t == null) return;
    if (_parentCode != null) {
      final code = await ref.read(sampleRepoProvider).nextChildCode(_parentCode!);
      if (mounted) setState(() => _code.text = code);
      return;
    }
    final settings = await ref.read(settingsRepoProvider).get();
    final code = await ref.read(sampleRepoProvider).nextCode(
          pattern: settings.idPattern,
          prefix: t.codePrefix,
          date: _collectedAt,
          collector: settings.collectorTag,
        );
    if (mounted) setState(() => _code.text = code);
  }

  /// Primeira amostra: o formato usa {COLETOR}, mas não há código nem nome
  /// do coletor. Pede o código uma vez e salva nos ajustes.
  Future<void> _askCollectorCode(AppSettings settings) async {
    final raw = await promptText(
      context,
      title: 'Código do coletor',
      message: 'Cada celular usa um código curto (ex.: suas iniciais) no código das amostras, '
          'para que amostras de pessoas diferentes nunca tenham o mesmo código ao juntar os dados.',
      label: 'Código (1 a 4 letras)',
      hint: 'AS',
      maxLength: 4,
      fieldKey: const Key('collector-code-field'),
      confirmLabel: 'Salvar',
      cancelable: false,
      capitalization: TextCapitalization.characters,
    );
    final code = normalizeCollectorCode(raw ?? '');
    if (code.isEmpty) return;
    await ref.read(settingsRepoProvider).save(settings.copyWith(collectorCode: code));
  }

  // ---------------------------------------------------------------------------
  // GPS
  // ---------------------------------------------------------------------------

  /// Liga o GPS e acompanha as leituras, ficando com a mais precisa.
  Future<void> _startGps() async {
    _stopGps();
    final loc = ref.read(locationServiceProvider);
    setState(() {
      _gpsActive = true;
      _gpsError = null;
      _gpsErrorAction = null;
    });
    try {
      if (await loc.needsPermissionPrompt()) {
        if (!mounted) return;
        final ok = await confirm(
          context,
          title: 'Permitir localização',
          message: 'O SampleTag registra automaticamente onde a amostra foi coletada '
              '(latitude, longitude, altitude e precisão). Os dados ficam somente no aparelho.',
          confirmLabel: 'Continuar',
        );
        if (!ok) {
          _gpsFailed('Localização não autorizada. Digite as coordenadas ou toque em atualizar.');
          return;
        }
      }
      await loc.ensureReady();
    } on LocationServiceDisabled catch (e) {
      _gpsFailed(e.message, ('Ativar', loc.openLocationSettings));
      return;
    } on LocationPermissionPermanentlyDenied catch (e) {
      _gpsFailed(e.message, ('Abrir ajustes', loc.openAppSettings));
      return;
    } on Object catch (e) {
      _gpsFailed(friendlyError(e));
      return;
    }
    if (!mounted) return;
    _gpsTimer = Timer(_gpsMaxWait, () {
      final got = _accuracy != null;
      _stopGps();
      if (!got) _gpsFailed('Sem sinal de GPS. Vá para um local aberto e toque em atualizar.');
    });
    _gpsSub = loc.stream().listen(
      (p) {
        if (!mounted) return;
        final first = _accuracy == null || _lat.text.isEmpty;
        if (first || p.accuracy < _accuracy!) _applyPosition(p);
        if (!_geocoded) {
          _geocoded = true;
          _reverseGeocode(p.latitude, p.longitude);
        }
        if (p.accuracy <= LocationService.goodAccuracyMeters) _stopGps();
      },
      onError: (Object e) {
        _stopGps();
        _gpsFailed(friendlyError(e));
      },
    );
  }

  void _stopGps() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _gpsTimer?.cancel();
    _gpsTimer = null;
    if (_gpsActive && mounted) setState(() => _gpsActive = false);
    _gpsActive = false;
  }

  void _gpsFailed(String msg, [(String, Future<void> Function())? action]) {
    if (!mounted) return;
    setState(() {
      _gpsActive = false;
      _gpsError = msg;
      _gpsErrorAction = action;
    });
  }

  /// O usuário digitou as coordenadas: o GPS não deve sobrescrevê-las.
  void _manualCoords() {
    _stopGps();
    _changed();
  }

  void _applyPosition(Position p) {
    setState(() {
      _lat.text = fmtCoord(p.latitude);
      _lon.text = fmtCoord(p.longitude);
      _altitude = p.altitude;
      _accuracy = p.accuracy;
      _gpsError = null;
    });
    // Posição automática numa ficha intocada não conta como alteração.
    if (_dirty) _changed();
  }

  /// Preenche município/UF vazios. Primeiro usa os limites do IBGE
  /// embutidos (funciona sem internet e devolve nomes oficiais); se o ponto
  /// cair fora do Brasil, tenta a geocodificação online.
  Future<void> _reverseGeocode(double lat, double lon) async {
    if (_city.text.isNotEmpty && _uf.text.isNotEmpty) return;
    String? city, uf;
    try {
      final local = await ref.read(geoLibraryProvider).locate(lat, lon);
      if (local != null) {
        city = local.municipality;
        uf = local.uf;
      }
    } on Object {
      // Asset ilegível: segue para a geocodificação online.
    }
    if (city == null || city.isEmpty) {
      final place = await ref.read(geocodingServiceProvider).reverse(lat, lon);
      city = place?.municipality ?? city;
      uf ??= place?.state;
    }
    if (!mounted) return;
    setState(() {
      if (_city.text.isEmpty && (city ?? '').isNotEmpty) _city.text = city!;
      if (_uf.text.isEmpty && (uf ?? '').isNotEmpty) _uf.text = uf!;
    });
    if (_dirty) _changed();
  }

  Future<void> _waitBetterAccuracy() async {
    final pos = await showDialog<Position>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AccuracyDialog(stream: ref.read(locationServiceProvider).stream()),
    );
    if (pos != null) {
      _stopGps();
      _applyPosition(pos);
      _changed();
      await _reverseGeocode(pos.latitude, pos.longitude);
    }
  }

  // ---------------------------------------------------------------------------
  // Fotos
  // ---------------------------------------------------------------------------

  Future<void> _addPhotos({required bool camera}) async {
    try {
      final names = await ref.read(photoServiceProvider).pick(fromCamera: camera);
      if (names.isEmpty) return;
      setState(() {
        _photos.addAll(names);
        _newPhotos.addAll(names);
      });
      _changed();
    } on PlatformException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('access_denied') || e.code.contains('permission');
      showMessage(
        context,
        denied
            ? 'Permissão de ${camera ? 'câmera' : 'fotos'} negada. Libere nas configurações do aparelho.'
            : 'Não foi possível abrir a ${camera ? 'câmera' : 'galeria'}: ${e.message ?? e.code}',
        error: true,
      );
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _removePhoto(String name) async {
    final ok = await confirm(context,
        title: 'Remover foto?', message: 'A foto será removida desta amostra.', confirmLabel: 'Remover', destructive: true);
    if (!ok) return;
    setState(() => _photos.remove(name));
    if (_newPhotos.remove(name)) await ref.read(photoServiceProvider).deleteFile(name);
    _changed();
  }

  // ---------------------------------------------------------------------------
  // Salvar / sair
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (_template == null) {
      showMessage(context, 'Escolha o modelo de ficha.', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      showMessage(context, 'Verifique os campos destacados.', error: true);
      return;
    }
    final repo = ref.read(sampleRepoProvider);
    if (await repo.codeExists(_code.text, exceptId: widget.existing?.id)) {
      if (mounted) showMessage(context, 'Já existe uma amostra com o código ${_code.text.trim()}.', error: true);
      return;
    }
    _stopGps();
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final e = widget.existing;
      final sample = Sample(
        id: e?.id ?? const Uuid().v4(),
        sampleCode: _code.text.trim(),
        templateId: _template!.id,
        category: _category,
        collectedAt: _collectedAt,
        collectorName: _collector.text.trim(),
        collectorContact: _contact.text.trim(),
        cloneGenotype: _clone.text.trim(),
        originProperty: _origin.text.trim(),
        municipality: _city.text.trim(),
        state: _uf.text.trim().toUpperCase(),
        latitude: _parseCoord(_lat.text),
        longitude: _parseCoord(_lon.text),
        altitude: _altitude,
        gpsAccuracyMeters: _accuracy,
        photos: _photos,
        notes: _notes.text.trim(),
        storageInstruction: _storage.text.trim(),
        customFields: Map.of(_custom)..removeWhere((_, v) => v == null || (v is String && v.isEmpty)),
        parentId: _parentId,
        createdAt: e?.createdAt ?? now,
        updatedAt: now,
      );
      await repo.upsert(sample);
      // Fotos removidas de uma amostra existente: apaga os arquivos.
      for (final old in e?.photos ?? const <String>[]) {
        if (!_photos.contains(old)) await ref.read(photoServiceProvider).deleteFile(old);
      }
      _draftTimer?.cancel();
      await ref.read(settingsRepoProvider).clearDraft(_draftSlot);
      if (!mounted) return;
      showMessage(context, 'Amostra ${sample.sampleCode} salva.');
      Navigator.pop(context, sample);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static double? _parseCoord(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _onExit() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sair sem salvar?'),
        content: const Text('O rascunho fica guardado e pode ser restaurado depois.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'discard'), child: const Text('Descartar')),
          TextButton(onPressed: () => Navigator.pop(c, 'stay'), child: const Text('Continuar editando')),
          FilledButton(onPressed: () => Navigator.pop(c, 'keep'), child: const Text('Manter rascunho')),
        ],
      ),
    );
    if (!mounted || choice == null || choice == 'stay') return;
    _draftTimer?.cancel();
    if (choice == 'discard') {
      await ref.read(settingsRepoProvider).clearDraft(_draftSlot);
      for (final p in _newPhotos) {
        await ref.read(photoServiceProvider).deleteFile(p);
      }
    } else {
      await ref.read(settingsRepoProvider).saveDraft(_draftSlot, _toDraft());
    }
    if (mounted) Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final templates = ref.watch(templatesProvider).value ?? const <SampleTemplate>[];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? l.editSample : widget.parent != null ? 'Nova amostra técnica' : l.newSample),
          actions: [
            TextButton(
              key: const Key('save-sample'),
              onPressed: _saving || !_ready ? null : _save,
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).appBarTheme.foregroundColor),
              child: Text(l.save.toUpperCase()),
            ),
          ],
        ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    if (_parentCode != null || _parentId != null)
                      Card(
                        margin: const EdgeInsets.only(top: 8),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.account_tree_outlined),
                          title: Text('Derivada de ${_parentCode ?? 'amostra excluída'}'),
                          subtitle: const Text('Local, coletor e campos vieram da amostra de origem.'),
                        ),
                      ),
                    const SectionTitle('Modelo de ficha'),
                    DropdownButtonFormField<String>(
                      key: const Key('template-field'),
                      initialValue: _template?.id,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Modelo *'),
                      items: [
                        for (final t in templates)
                          DropdownMenuItem(
                            value: t.id,
                            child: Row(children: [TemplateDot(t), const SizedBox(width: 8), Text(t.name)]),
                          ),
                      ],
                      validator: (v) => v == null ? 'Escolha o modelo' : null,
                      onChanged: (id) {
                        final t = templates.firstWhere((t) => t.id == id);
                        _applyTemplate(t);
                      },
                    ),
                    if (_template != null) ..._mainFields(context),
                  ],
                ),
              ),
        bottomNavigationBar: !_ready
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Salvar amostra'),
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _mainFields(BuildContext context) {
    final t = _template!;
    InputDecoration dec(String label, {String? hint, Widget? suffix}) =>
        InputDecoration(labelText: label, hintText: hint, suffixIcon: suffix);
    Widget gap() => const SizedBox(height: 12);

    return [
      gap(),
      TextFormField(
        key: const Key('code-field'),
        controller: _code,
        decoration: dec('Código da amostra *',
            suffix: IconButton(
              tooltip: 'Gerar novamente',
              icon: const Icon(Icons.autorenew),
              onPressed: () {
                _codeEdited = false;
                _generateCode();
                _changed();
              },
            )),
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o código' : null,
        onChanged: (_) {
          _codeEdited = true;
          _changed();
        },
      ),
      gap(),
      SegmentedButton<SampleCategory>(
        segments: [
          for (final c in SampleCategory.values) ButtonSegment(value: c, label: Text(c.label)),
        ],
        selected: {_category},
        onSelectionChanged: (s) {
          setState(() => _category = s.first);
          _changed();
        },
      ),
      gap(),
      OutlinedButton.icon(
        icon: const Icon(Icons.event),
        label: Text('Coleta: ${fmtDateTime(_collectedAt)}'),
        onPressed: _pickDateTime,
      ),
      const SectionTitle('Coletor'),
      TextFormField(controller: _collector, decoration: dec('Nome do coletor'), textCapitalization: TextCapitalization.words, onChanged: (_) => _changed()),
      gap(),
      TextFormField(controller: _contact, decoration: dec('Contato (telefone/e-mail)'), onChanged: (_) => _changed()),
      const SectionTitle('Amostra'),
      TextFormField(key: const Key('clone-field'), controller: _clone, decoration: dec('Clone/genótipo'), onChanged: (_) => _changed()),
      gap(),
      TextFormField(controller: _origin, decoration: dec('Origem/propriedade'), textCapitalization: TextCapitalization.words, onChanged: (_) => _changed()),
      for (final f in t.fields) ...[gap(), _customField(f)],
      const SectionTitle('Localização'),
      _locationCard(context),
      gap(),
      Row(children: [
        Expanded(
          flex: 3,
          child: TextFormField(controller: _city, decoration: dec('Município'), textCapitalization: TextCapitalization.words, onChanged: (_) => _changed()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _uf,
            decoration: dec('UF'),
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z]'))],
            validator: (v) => v != null && v.isNotEmpty && v.length != 2 ? '2 letras' : null,
            onChanged: (_) => _changed(),
          ),
        ),
      ]),
      const SectionTitle('Fotos'),
      _photosSection(),
      const SectionTitle('Observações e armazenamento'),
      TextFormField(controller: _notes, decoration: dec('Observações'), maxLines: 4, minLines: 2, onChanged: (_) => _changed()),
      gap(),
      TextFormField(controller: _storage, decoration: dec('Instrução de armazenamento'), onChanged: (_) => _changed()),
    ];
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _collectedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_collectedAt));
    setState(() => _collectedAt = DateTime(d.year, d.month, d.day, t?.hour ?? _collectedAt.hour, t?.minute ?? _collectedAt.minute));
    _changed();
  }

  Widget _customField(TemplateField f) {
    final label = '${f.label}${f.required ? ' *' : ''}';
    String? req(Object? v) =>
        f.required && (v == null || (v is String && v.trim().isEmpty)) ? 'Campo obrigatório' : null;
    switch (f.type) {
      case FieldType.text:
        return TextFormField(
          controller: _customText.putIfAbsent(f.key, TextEditingController.new),
          decoration: InputDecoration(labelText: label),
          validator: req,
          onChanged: (v) {
            _custom[f.key] = v;
            _changed();
          },
        );
      case FieldType.number:
        return TextFormField(
          controller: _customText.putIfAbsent(f.key, TextEditingController.new),
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          validator: (v) {
            final r = req(v);
            if (r != null) return r;
            if (v != null && v.trim().isNotEmpty && double.tryParse(v.replaceAll(',', '.')) == null) {
              return 'Número inválido';
            }
            return null;
          },
          onChanged: (v) {
            _custom[f.key] = double.tryParse(v.replaceAll(',', '.'));
            _changed();
          },
        );
      case FieldType.list:
        final current = _custom[f.key] as String?;
        return DropdownButtonFormField<String>(
          key: Key('custom-${f.key}'),
          initialValue: f.options.contains(current) ? current : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [for (final o in f.options) DropdownMenuItem(value: o, child: Text(o))],
          validator: req,
          onChanged: (v) {
            setState(() => _custom[f.key] = v);
            _changed();
          },
        );
      case FieldType.date:
        final iso = _custom[f.key] as String?;
        return FormField<String>(
          initialValue: iso,
          validator: (_) => req(_custom[f.key]),
          builder: (state) => InputDecorator(
            decoration: InputDecoration(labelText: label, errorText: state.errorText),
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(iso ?? '') ?? DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2100),
                );
                if (d != null) {
                  setState(() => _custom[f.key] = fmtIsoDate(d));
                  state.didChange(fmtIsoDate(d));
                  _changed();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(iso == null ? 'Toque para escolher' : fmtCustomValue(iso)),
              ),
            ),
          ),
        );
    }
  }

  Widget _locationCard(BuildContext context) {
    final acc = _accuracy;
    final poor = acc != null && acc > LocationService.goodAccuracyMeters;
    final scheme = Theme.of(context).colorScheme;
    String? coordValidator(String? v, double limit) {
      if (v == null || v.trim().isEmpty) return null;
      final d = _parseCoord(v);
      if (d == null || d.abs() > limit) return 'Valor inválido';
      return null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _gpsStatus(context),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _lat,
                decoration: const InputDecoration(labelText: 'Latitude', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (v) => coordValidator(v, 90),
                onChanged: (_) => _manualCoords(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _lon,
                decoration: const InputDecoration(labelText: 'Longitude', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (v) => coordValidator(v, 180),
                onChanged: (_) => _manualCoords(),
              ),
            ),
          ]),
          if (acc != null || _altitude != null) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (acc != null)
                Chip(
                  avatar: Icon(poor ? Icons.warning_amber : Icons.gps_fixed,
                      color: poor ? AppWarnColor.of(context) : scheme.primary),
                  label: Text('Precisão: ±${fmtMeters(acc)}'),
                ),
              if (_altitude != null) Chip(avatar: const Icon(Icons.terrain), label: Text('Altitude: ${fmtMeters(_altitude, decimals: 0)}')),
            ]),
          ],
          if (poor && !_gpsActive) ...[
            const SizedBox(height: 8),
            Text(
              'Precisão acima de ${LocationService.goodAccuracyMeters.toInt()} m. '
              'Afaste-se de árvores e construções e aguarde um sinal melhor.',
              style: TextStyle(color: AppWarnColor.of(context), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _waitBetterAccuracy,
              icon: const Icon(Icons.hourglass_bottom),
              label: const Text('Aguardar melhor precisão'),
            ),
          ],
        ]),
      ),
    );
  }

  /// Situação do GPS automático, com botão discreto para nova leitura.
  Widget _gpsStatus(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final acc = _accuracy;
    final Widget icon;
    final String text;
    if (_gpsActive) {
      icon = const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5));
      text = acc == null ? 'Buscando sinal de GPS…' : 'Refinando a precisão (±${fmtMeters(acc)})…';
    } else if (_gpsError != null) {
      icon = Icon(Icons.location_disabled, color: AppWarnColor.of(context));
      text = _gpsError!;
    } else if (_lat.text.trim().isNotEmpty) {
      icon = Icon(Icons.gps_fixed, color: scheme.primary);
      text = acc == null ? 'Coordenadas informadas.' : 'Localização registrada.';
    } else {
      icon = const Icon(Icons.location_searching);
      text = 'Sem coordenadas.';
    }
    final action = _gpsErrorAction;
    return Row(children: [
      icon,
      const SizedBox(width: 10),
      Expanded(child: Text(text, key: const Key('gps-status'), style: const TextStyle(fontWeight: FontWeight.w600))),
      if (action != null) TextButton(onPressed: () => action.$2(), child: Text(action.$1)),
      if (!_gpsActive)
        IconButton(
          key: const Key('capture-location'),
          tooltip: 'Atualizar localização',
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _geocoded = false;
            _accuracy = null;
            _startGps();
          },
        ),
    ]);
  }

  Widget _photosSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_photos.isNotEmpty)
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Stack(children: [
              PhotoThumb(_photos[i], size: 110),
              Positioned(
                right: 2,
                top: 2,
                child: IconButton.filled(
                  tooltip: 'Remover foto',
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => _removePhoto(_photos[i]),
                ),
              ),
            ]),
          ),
        ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => _addPhotos(camera: true),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Câmera'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addPhotos(camera: false),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeria'),
          ),
        ),
      ]),
    ]);
  }
}

/// Cor de aviso com bom contraste nos dois temas.
class AppWarnColor {
  static Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF0B35A) : const Color(0xFF9A5B00);
}

/// Diálogo que acompanha o GPS e mostra a melhor precisão obtida.
class _AccuracyDialog extends StatefulWidget {
  const _AccuracyDialog({required this.stream});
  final Stream<Position> stream;

  @override
  State<_AccuracyDialog> createState() => _AccuracyDialogState();
}

class _AccuracyDialogState extends State<_AccuracyDialog> {
  StreamSubscription<Position>? _sub;
  Position? _best;
  Object? _error;
  final _started = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen(
      (p) => setState(() {
        if (_best == null || p.accuracy < _best!.accuracy) _best = p;
      }),
      onError: (Object e) => setState(() => _error = e),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _best;
    final good = b != null && b.accuracy <= LocationService.goodAccuracyMeters;
    final elapsed = DateTime.now().difference(_started).inSeconds;
    return AlertDialog(
      title: const Text('Aguardando precisão'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_error != null)
          Text(friendlyError(_error!))
        else ...[
          Text(
            b == null ? '—' : '±${fmtMeters(b.accuracy)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: good ? Theme.of(context).colorScheme.primary : AppWarnColor.of(context),
                ),
          ),
          const SizedBox(height: 8),
          Text(good ? 'Precisão boa. Pode usar esta posição.' : 'Mantenha o aparelho parado, com visão do céu. ($elapsed s)'),
          const SizedBox(height: 12),
          if (!good) const LinearProgressIndicator(),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: b == null ? null : () => Navigator.pop(context, b),
          child: const Text('Usar esta posição'),
        ),
      ],
    );
  }
}
