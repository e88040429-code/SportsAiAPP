import 'dart:typed_data';

/// MIME type Chrome's `<video>` element is most likely to accept.
String videoMimeForImport({String? extension, Uint8List? bytes}) {
  if (bytes != null && bytes.length >= 12) {
    // EBML — WebM / Matroska
    if (bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      return 'video/webm';
    }
    // RIFF AVI
    if (_ascii(bytes, 0, 4) == 'RIFF' && _ascii(bytes, 8, 4) == 'AVI ') {
      return 'video/x-msvideo';
    }
    // ISO BMFF — MP4 / MOV / M4V
    if (_ascii(bytes, 4, 4) == 'ftyp') {
      return 'video/mp4';
    }
  }

  return switch (extension?.toLowerCase()) {
    'webm' => 'video/webm',
    'mkv' => 'video/webm',
    'avi' => 'video/x-msvideo',
    'mov' || 'm4v' || 'mp4' => 'video/mp4',
    _ => 'video/mp4',
  };
}

String _ascii(Uint8List bytes, int start, int length) {
  if (start + length > bytes.length) return '';
  return String.fromCharCodes(bytes.sublist(start, start + length));
}
