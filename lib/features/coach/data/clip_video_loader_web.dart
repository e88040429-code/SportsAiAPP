import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

Future<VideoPlayerController> loadClipVideo(PlatformFile file) async {
  final path = file.path;
  if (path != null &&
      (path.startsWith('blob:') ||
          path.startsWith('http:') ||
          path.startsWith('https:'))) {
    return VideoPlayerController.networkUrl(Uri.parse(path));
  }

  if (file.bytes != null) {
    // Blob URLs work in Chrome; data: URIs often fail with
    // "The video has been found to be unsuitable".
    final url = _blobUrl(file.bytes!, _mimeFor(file.extension));
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }

  throw Exception('No video data returned from picker');
}

String _mimeFor(String? extension) {
  return switch (extension?.toLowerCase()) {
    'webm' => 'video/webm',
    'mov' => 'video/mp4', // Chrome rarely plays quicktime; try mp4 container hint
    'm4v' => 'video/mp4',
    'avi' => 'video/mp4',
    'mp4' => 'video/mp4',
    _ => 'video/mp4',
  };
}

String _blobUrl(Uint8List bytes, String mimeType) {
  final parts = <JSAny>[bytes.toJS].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: mimeType),
  );
  return web.URL.createObjectURL(blob);
}
