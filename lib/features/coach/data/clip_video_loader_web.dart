import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import 'clip_video_mime.dart';

Future<VideoPlayerController> loadClipVideo(PlatformFile file) async {
  // On web, PlatformFile.path throws — always use bytes.
  final bytes = file.bytes;
  if (bytes != null && bytes.isNotEmpty) {
    // Blob URLs work in Chrome; data: URIs often fail with
    // "The video has been found to be unsuitable".
    final mime = videoMimeForImport(
      extension: file.extension,
      bytes: bytes,
    );
    final url = _blobUrl(bytes, mime);
    return _networkController(url);
  }

  throw Exception('No video data returned from picker');
}

VideoPlayerController _networkController(String url) {
  return VideoPlayerController.networkUrl(
    Uri.parse(url),
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
}

String _blobUrl(Uint8List bytes, String mimeType) {
  // Copy if this is a view into a larger buffer — wasm Blob parts need a
  // tight Uint8Array or Chrome reports MEDIA_ERR_SRC_NOT_SUPPORTED.
  final copy = bytes.offsetInBytes == 0 &&
          bytes.lengthInBytes == bytes.buffer.lengthInBytes
      ? bytes
      : Uint8List.fromList(bytes);

  final blob = web.Blob(
    [copy.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  return web.URL.createObjectURL(blob);
}
