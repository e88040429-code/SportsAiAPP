import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'picked_file_bytes_stub.dart'
    if (dart.library.html) 'picked_file_bytes_web.dart'
    if (dart.library.io) 'picked_file_bytes_io.dart' as impl;

Future<Uint8List?> readPickedFileBytes(PlatformFile file) {
  return impl.readPickedFileBytes(file);
}
