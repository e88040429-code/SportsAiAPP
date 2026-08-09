import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Allowed training-clip extensions (matches the file picker filter).
const Set<String> kAllowedClipExtensions = {
  'mp4',
  'mov',
  'm4v',
  'webm',
  'avi',
  'mkv',
};

/// Still photos for pose check (balance / symmetry — no timing).
const Set<String> kAllowedImageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'webp',
  'bmp',
  'gif',
};

/// Video clips + still images accepted by Import.
const Set<String> kAllowedImportExtensions = {
  ...kAllowedClipExtensions,
  ...kAllowedImageExtensions,
};

bool isImageImportExtension(String? ext) {
  final value = ext?.toLowerCase().trim();
  return value != null && kAllowedImageExtensions.contains(value);
}

bool isVideoImportExtension(String? ext) {
  final value = ext?.toLowerCase().trim();
  return value != null && kAllowedClipExtensions.contains(value);
}

/// Validates a picked file **before** opening the describe / Generate panel.
abstract final class ClipImportValidator {
  /// Returns an error message if the file must be rejected; otherwise `null`.
  static String? validate(PlatformFile file) {
    final name = file.name.trim();
    if (name.isEmpty) {
      return 'Could not read that file. Pick a video clip or photo and try again.';
    }

    final ext = _extensionOf(file);
    if (ext == null || !kAllowedImportExtensions.contains(ext)) {
      return 'Only video clips or still photos are allowed '
          '(MP4, MOV, M4V, WebM, AVI, MKV, JPG, PNG, WebP, BMP, GIF).';
    }

    final size = _resolvedSize(file);
    if (size != null && size <= 0) {
      return 'That file is empty (0 bytes). Pick a real clip or photo.';
    }

    final bytes = file.bytes;
    if (bytes != null) {
      if (bytes.isEmpty) {
        return 'That file is empty (0 bytes). Pick a real clip or photo.';
      }

      if (_looksLikeDocument(bytes)) {
        return 'That file looks like a document. '
            'Pick a video clip or a still photo instead.';
      }

      final imageExt = isImageImportExtension(ext);
      final videoExt = isVideoImportExtension(ext);

      if (imageExt) {
        if (_looksLikeVideoContainer(bytes)) {
          return 'That file doesn’t look like a still photo. '
              'Pick a JPG, PNG, or similar image.';
        }
        if (bytes.length >= 12 && !_looksLikeImage(bytes)) {
          return 'That file doesn’t look like a still photo. '
              'Pick a JPG, PNG, WebP, or similar image.';
        }
      }

      if (videoExt) {
        if (_looksLikeImage(bytes)) {
          return 'That file isn’t a video (it looks like an image or document). '
              'Pick an MP4, MOV, or similar clip — or import it as a photo.';
        }
        if (!_looksLikeVideoContainer(bytes)) {
          return 'That file doesn’t look like a video clip. '
              'Pick an MP4, MOV, WebM, or similar file.';
        }
      }
    }

    // Path-only picks (mobile/desktop without bytes): extension + size already checked.
    return null;
  }

  static String? _extensionOf(PlatformFile file) {
    final fromPicker = file.extension?.toLowerCase().trim();
    if (fromPicker != null && fromPicker.isNotEmpty) return fromPicker;

    final name = file.name;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  static int? _resolvedSize(PlatformFile file) {
    if (file.size > 0) return file.size;
    final bytes = file.bytes;
    if (bytes != null) return bytes.length;
    if (file.size == 0) return 0;
    return null;
  }

  static bool _looksLikeImage(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    // GIF
    if (_ascii(bytes, 0, 3) == 'GIF') return true;
    // BMP
    if (_ascii(bytes, 0, 2) == 'BM') return true;
    // WebP image (RIFF....WEBP)
    if (bytes.length >= 12 &&
        _ascii(bytes, 0, 4) == 'RIFF' &&
        _ascii(bytes, 8, 4) == 'WEBP') {
      return true;
    }

    return false;
  }

  static bool _looksLikeDocument(Uint8List bytes) {
    if (bytes.length < 4) return false;
    if (_ascii(bytes, 0, 4) == '%PDF') return true;
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) return true;
    return false;
  }

  static bool _looksLikeVideoContainer(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // EBML — WebM / Matroska (MKV)
    if (bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      return true;
    }

    // RIFF AVI
    if (_ascii(bytes, 0, 4) == 'RIFF' && _ascii(bytes, 8, 4) == 'AVI ') {
      return true;
    }

    // ISO BMFF — MP4 / MOV / M4V (`....ftyp`)
    if (_ascii(bytes, 4, 4) == 'ftyp') return true;

    // Some captures start with a larger box; scan a small window for `ftyp`.
    final scanLimit = bytes.length < 64 ? bytes.length - 4 : 60;
    for (var i = 0; i <= scanLimit; i++) {
      if (_ascii(bytes, i, 4) == 'ftyp') return true;
    }

    return false;
  }

  static String _ascii(Uint8List bytes, int start, int length) {
    if (start + length > bytes.length) return '';
    return String.fromCharCodes(bytes.sublist(start, start + length));
  }
}
