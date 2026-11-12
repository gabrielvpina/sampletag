import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/errors.dart';

/// Armazena e processa fotos das amostras.
///
/// As fotos ficam em `<documentos do app>/photos/` e o banco guarda apenas o
/// nome do arquivo (caminho relativo).
class PhotoService {
  PhotoService({ImagePicker? picker, Directory? baseDir})
      : _picker = picker ?? ImagePicker(),
        _baseDirOverride = baseDir;

  final ImagePicker _picker;
  final Directory? _baseDirOverride;
  Directory? _dir;

  /// Lado maior das fotos guardadas e qualidade JPEG.
  static const storedMaxSide = 1600;
  static const storedQuality = 80;

  /// Lado maior das miniaturas usadas no relatório HTML e qualidade.
  static const thumbMaxSide = 400;
  static const thumbQuality = 70;

  Future<Directory> photosDir() async {
    if (_dir != null) return _dir!;
    final base = _baseDirOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'photos'));
    await dir.create(recursive: true);
    return _dir = dir;
  }

  /// Caminho absoluto a partir do nome salvo no banco.
  Future<String> resolve(String name) async => p.join((await photosDir()).path, name);

  /// Abre a câmera (ou galeria) e salva as fotos comprimidas.
  /// Retorna os nomes dos arquivos salvos.
  Future<List<String>> pick({required bool fromCamera}) async {
    final List<XFile> picked;
    if (fromCamera) {
      final f = await _picker.pickImage(source: ImageSource.camera);
      picked = f == null ? const [] : [f];
    } else {
      picked = await _picker.pickMultiImage();
    }
    final names = <String>[];
    for (final f in picked) {
      names.add(await saveCompressed(f.path));
    }
    return names;
  }

  /// Comprime para lado maior [storedMaxSide] px, JPEG [storedQuality]% e
  /// grava na pasta de fotos.
  Future<String> saveCompressed(String sourcePath) async {
    final name = '${const Uuid().v4()}.jpg';
    final target = await resolve(name);
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        target,
        // O plugin reduz a imagem mantendo a proporção até que caiba em
        // minWidth x minHeight; usar o mesmo valor limita o lado maior.
        minWidth: storedMaxSide,
        minHeight: storedMaxSide,
        quality: storedQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (result == null) {
        // Formato não suportado pelo compressor: copia o original.
        await File(sourcePath).copy(target);
      }
    } on FileSystemException catch (e) {
      throw AppException(friendlyError(e));
    }
    return name;
  }

  /// Miniatura em memória para o relatório HTML (lado maior ~400 px, JPEG 70%).
  Future<Uint8List?> thumbnail(String name) async {
    final path = await resolve(name);
    if (!await File(path).exists()) return null;
    return FlutterImageCompress.compressWithFile(
      path,
      minWidth: thumbMaxSide,
      minHeight: thumbMaxSide,
      quality: thumbQuality,
      format: CompressFormat.jpeg,
    );
  }

  Future<void> deleteFile(String name) async {
    final f = File(await resolve(name));
    if (await f.exists()) await f.delete();
  }

  /// Recupera fotos perdidas pelo Android quando o app é morto enquanto a
  /// câmera está aberta.
  Future<List<String>> recoverLost() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null) return const [];
    return [for (final f in response.files!) await saveCompressed(f.path)];
  }
}
