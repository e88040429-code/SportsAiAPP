import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

Future<VideoPlayerController> loadClipVideo(PlatformFile file) async {
  if (file.path == null) {
    throw Exception('No file path available');
  }
  return VideoPlayerController.file(File(file.path!));
}
