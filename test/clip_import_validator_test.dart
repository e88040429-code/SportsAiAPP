import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/features/coach/data/clip_import_validator.dart';

PlatformFile _file({
  required String name,
  required List<int> bytes,
  int? size,
}) {
  final data = Uint8List.fromList(bytes);
  return PlatformFile(
    name: name,
    size: size ?? data.length,
    bytes: data,
  );
}

void main() {
  group('ClipImportValidator', () {
    test('rejects empty / 0-byte files', () {
      final empty = _file(name: 'clip.mp4', bytes: const []);
      expect(ClipImportValidator.validate(empty), contains('empty'));

      final zeroSized = PlatformFile(
        name: 'clip.mp4',
        size: 0,
        bytes: Uint8List(0),
      );
      expect(ClipImportValidator.validate(zeroSized), contains('empty'));
    });

    test('rejects disallowed extensions like pdf', () {
      final pdf = _file(
        name: 'doc.pdf',
        bytes: '%PDF-1.4'.codeUnits,
      );
      expect(ClipImportValidator.validate(pdf), contains('Only video clips or still photos'));
    });

    test('accepts still photo extensions with image magic', () {
      final png = _file(
        name: 'pose.png',
        bytes: const [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0,
        ],
      );
      expect(ClipImportValidator.validate(png), isNull);

      final jpeg = _file(
        name: 'stance.jpg',
        bytes: const [0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0],
      );
      expect(ClipImportValidator.validate(jpeg), isNull);
    });

    test('rejects image bytes even when renamed to .mp4', () {
      final pngAsMp4 = _file(
        name: 'fake.mp4',
        bytes: const [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0,
        ],
      );
      expect(ClipImportValidator.validate(pngAsMp4), contains('isn’t a video'));

      final jpegAsMp4 = _file(
        name: 'fake.mp4',
        bytes: const [0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0],
      );
      expect(ClipImportValidator.validate(jpegAsMp4), contains('isn’t a video'));
    });

    test('accepts MP4/MOV-style ftyp containers', () {
      final mp4 = _file(
        name: 'spike.mp4',
        bytes: const [
          0x00, 0x00, 0x00, 0x18,
          0x66, 0x74, 0x79, 0x70, // ftyp
          0x69, 0x73, 0x6F, 0x6D, // isom
          0x00, 0x00, 0x00, 0x00,
        ],
      );
      expect(ClipImportValidator.validate(mp4), isNull);
    });

    test('accepts WebM/MKV EBML header', () {
      final webm = _file(
        name: 'drill.webm',
        bytes: const [
          0x1A, 0x45, 0xDF, 0xA3,
          0x01, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00,
        ],
      );
      expect(ClipImportValidator.validate(webm), isNull);
    });

    test('rejects random bytes with a video extension', () {
      final junk = _file(
        name: 'nope.mp4',
        bytes: List<int>.generate(32, (i) => i + 3),
      );
      expect(ClipImportValidator.validate(junk), contains('doesn’t look like'));
    });
  });
}
