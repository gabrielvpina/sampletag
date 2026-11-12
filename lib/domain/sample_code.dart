// Geração do código legível da amostra (ex.: CAC-2026-0001).

/// Monta o código a partir de um padrão com tokens.
///
/// Tokens suportados:
/// - `{PREFIXO}`: prefixo do modelo (ex.: CAC)
/// - `{AAAA}` / `{AA}`: ano com 4 / 2 dígitos
/// - `{MM}` / `{DD}`: mês / dia com 2 dígitos
/// - `{SEQ}`: sequência com 4 dígitos; `{SEQn}`: sequência com n dígitos
String formatSampleCode({
  required String pattern,
  required String prefix,
  required DateTime date,
  required int sequence,
}) {
  String two(int v) => v.toString().padLeft(2, '0');
  var out = pattern
      .replaceAll('{PREFIXO}', prefix.toUpperCase())
      .replaceAll('{AAAA}', date.year.toString().padLeft(4, '0'))
      .replaceAll('{AA}', two(date.year % 100))
      .replaceAll('{MM}', two(date.month))
      .replaceAll('{DD}', two(date.day));
  out = out.replaceAllMapped(RegExp(r'\{SEQ(\d*)\}'), (m) {
    final width = m.group(1)!.isEmpty ? 4 : int.parse(m.group(1)!);
    return sequence.toString().padLeft(width, '0');
  });
  return out;
}

/// Converte o padrão em uma expressão regular que extrai a sequência de
/// códigos existentes com o mesmo prefixo e data. Usado para descobrir o
/// próximo número livre.
RegExp sampleCodeMatcher({
  required String pattern,
  required String prefix,
  required DateTime date,
}) {
  // Primeiro substitui os tokens fixos e marca a sequência; depois escapa o
  // restante para que caracteres como "." ou "-" sejam literais.
  const seqMark = '\u0000SEQ\u0000';
  final filled = formatSampleCode(
    pattern: pattern.replaceAll(RegExp(r'\{SEQ\d*\}'), seqMark),
    prefix: prefix,
    date: date,
    sequence: 0,
  );
  final parts = filled.split(seqMark).map(RegExp.escape).toList();
  return RegExp('^${parts.join(r'(\d+)')}\$');
}

/// Calcula a próxima sequência dado o conjunto de códigos existentes.
/// Códigos que não seguem o padrão (editados à mão) são ignorados.
int nextSequence({
  required Iterable<String> existingCodes,
  required String pattern,
  required String prefix,
  required DateTime date,
}) {
  final re = sampleCodeMatcher(pattern: pattern, prefix: prefix, date: date);
  var maxSeq = 0;
  for (final code in existingCodes) {
    final m = re.firstMatch(code);
    if (m == null || m.groupCount == 0) continue;
    final seq = int.tryParse(m.group(1)!) ?? 0;
    if (seq > maxSeq) maxSeq = seq;
  }
  return maxSeq + 1;
}

/// Gera o próximo código livre.
String nextSampleCode({
  required Iterable<String> existingCodes,
  required String pattern,
  required String prefix,
  required DateTime date,
}) {
  final codes = existingCodes.toSet();
  var seq = nextSequence(
      existingCodes: codes, pattern: pattern, prefix: prefix, date: date);
  // Se o padrão não tem {SEQ}, evita colisão acrescentando sufixo.
  var code = formatSampleCode(pattern: pattern, prefix: prefix, date: date, sequence: seq);
  if (!RegExp(r'\{SEQ\d*\}').hasMatch(pattern)) {
    var n = 2;
    final base = code;
    while (codes.contains(code)) {
      code = '$base-${n++}';
    }
    return code;
  }
  while (codes.contains(code)) {
    code = formatSampleCode(pattern: pattern, prefix: prefix, date: date, sequence: ++seq);
  }
  return code;
}
