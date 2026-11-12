// Dados iniciais: modelo "Cacau" pré-cadastrado e amostras de exemplo.
// Dart puro, para ser usado pelo app, pelos testes e pela ferramenta de demo.

import 'models.dart';

const cacauTemplateId = 'tpl-cacau';
const defaultDnaStorage = 'Armazenar a -20 °C (Análise de DNA/RNA)';

/// Modelo "Cacau", com os campos da ficha original.
///
/// Os campos-padrão da ficha (código, data, coletor, contato, clone/genótipo,
/// origem/propriedade, município, UF, coordenadas e observações) já fazem
/// parte de toda amostra; aqui ficam só os campos extras específicos do cacau.
const cacauTemplate = SampleTemplate(
  id: cacauTemplateId,
  name: 'Cacau',
  codePrefix: 'CAC',
  color: 0xFF3D5C40,
  defaultStorageInstruction: defaultDnaStorage,
  category: SampleCategory.biological,
  fields: [
    TemplateField(
      key: 'tecido',
      label: 'Tecido coletado',
      type: FieldType.list,
      required: true,
      options: ['Folha jovem', 'Folha madura', 'Fruto', 'Semente', 'Ramo', 'Flor'],
    ),
    TemplateField(key: 'numero_planta', label: 'Nº da planta'),
    TemplateField(key: 'idade_planta', label: 'Idade da planta (anos)', type: FieldType.number),
    TemplateField(
      key: 'sanidade',
      label: 'Estado fitossanitário',
      type: FieldType.list,
      options: ['Sadia', 'Vassoura-de-bruxa', 'Podridão-parda', 'Monilíase', 'Outro'],
    ),
    TemplateField(
      key: 'sistema',
      label: 'Sistema de cultivo',
      type: FieldType.list,
      options: ['Cabruca', 'Pleno sol', 'SAF', 'Outro'],
    ),
  ],
);

/// Cinco amostras de exemplo em fazendas de cacau do sul da Bahia.
/// Nomes de fazendas e coletores são fictícios; coordenadas aproximadas.
List<Sample> demoSamples({DateTime? now}) {
  final base = now ?? DateTime(2026, 11, 3, 8, 30);
  Sample s(
    int i, {
    required String clone,
    required String farm,
    required String city,
    required double lat,
    required double lon,
    required double alt,
    required double acc,
    required String collector,
    required String contact,
    required Map<String, Object?> custom,
    String notes = '',
    int dayOffset = 0,
  }) {
    final at = base.add(Duration(days: dayOffset, hours: i));
    return Sample(
      id: 'demo-$i',
      sampleCode: 'CAC-${at.year}-${i.toString().padLeft(4, '0')}',
      templateId: cacauTemplateId,
      category: SampleCategory.biological,
      collectedAt: at,
      collectorName: collector,
      collectorContact: contact,
      cloneGenotype: clone,
      originProperty: farm,
      municipality: city,
      state: 'BA',
      latitude: lat,
      longitude: lon,
      altitude: alt,
      gpsAccuracyMeters: acc,
      notes: notes,
      storageInstruction: defaultDnaStorage,
      customFields: custom,
      createdAt: at,
      updatedAt: at,
    );
  }

  return [
    s(1,
        clone: 'CCN-51',
        farm: 'Fazenda Boa Esperança',
        city: 'Ilhéus',
        lat: -14.7935,
        lon: -39.1720,
        alt: 62,
        acc: 4.8,
        collector: 'Ana Souza',
        contact: '(73) 99100-0001',
        custom: {'tecido': 'Folha jovem', 'numero_planta': 'P-014', 'idade_planta': 12, 'sanidade': 'Sadia', 'sistema': 'Cabruca'},
        notes: 'Planta vigorosa, frutos vermelhos.'),
    s(2,
        clone: 'PH-16',
        farm: 'Fazenda Santa Rita',
        city: 'Uruçuca',
        lat: -14.5872,
        lon: -39.2961,
        alt: 118,
        acc: 6.2,
        collector: 'Ana Souza',
        contact: '(73) 99100-0001',
        custom: {'tecido': 'Folha jovem', 'numero_planta': 'P-102', 'idade_planta': 8, 'sanidade': 'Sadia', 'sistema': 'Cabruca'}),
    s(3,
        clone: 'TSH-1188',
        farm: 'Sítio Rio do Braço',
        city: 'Itajuípe',
        lat: -14.6791,
        lon: -39.3802,
        alt: 135,
        acc: 12.5,
        collector: 'João Lima',
        contact: 'joao.lima@example.org',
        custom: {'tecido': 'Fruto', 'numero_planta': 'P-007', 'idade_planta': 20, 'sanidade': 'Vassoura-de-bruxa', 'sistema': 'SAF'},
        notes: 'Sintomas iniciais de vassoura-de-bruxa nos ramos.',
        dayOffset: 1),
    s(4,
        clone: 'CEPEC-2002',
        farm: 'Fazenda Primavera',
        city: 'Una',
        lat: -15.2805,
        lon: -39.0921,
        alt: 41,
        acc: 25.0,
        collector: 'João Lima',
        contact: 'joao.lima@example.org',
        custom: {'tecido': 'Semente', 'numero_planta': 'P-033', 'idade_planta': 5, 'sanidade': 'Sadia', 'sistema': 'Pleno sol'},
        notes: 'GPS com precisão baixa (mata fechada).',
        dayOffset: 2),
    s(5,
        clone: 'SJ-02',
        farm: 'Fazenda Serra Azul',
        city: 'Camacan',
        lat: -15.4140,
        lon: -39.5032,
        alt: 210,
        acc: 5.1,
        collector: 'Marina Costa',
        contact: '(73) 98800-0005',
        custom: {'tecido': 'Folha madura', 'numero_planta': 'P-210', 'idade_planta': 15, 'sanidade': 'Podridão-parda', 'sistema': 'Cabruca'},
        dayOffset: 3),
  ];
}
