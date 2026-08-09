import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> readPickedFileBytes(PlatformFile file) async {
  final inline = file.bytes;
  if (inline != null && inline.isNotEmpty) return inline;

  final path = file.path;
  if (path == null || path.isEmpty) return null;

  final loaded = await File(path).readAsBytes();
  if (loaded.isEmpty) return null;
  return loaded;
}
