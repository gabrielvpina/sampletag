import 'dart:io';

/// Erro com mensagem já pronta para o usuário.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Converte exceções comuns em mensagens amigáveis em português.
String friendlyError(Object error) {
  if (error is AppException) return error.message;
  if (error is FileSystemException) {
    final code = error.osError?.errorCode;
    // ENOSPC = 28 (Linux/Android e Darwin).
    if (code == 28 || (error.osError?.message.toLowerCase().contains('no space') ?? false)) {
      return 'Armazenamento cheio. Libere espaço no aparelho e tente novamente.';
    }
    return 'Erro ao acessar arquivo: ${error.message}';
  }
  final text = error.toString();
  if (text.toLowerCase().contains('no space left') || text.contains('SQLITE_FULL')) {
    return 'Armazenamento cheio. Libere espaço no aparelho e tente novamente.';
  }
  return 'Erro inesperado: $text';
}
