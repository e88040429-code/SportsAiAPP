import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

import 'clip_video_loader_stub.dart'
    if (dart.library.html) 'clip_video_loader_web.dart'
    if (dart.library.io) 'clip_video_loader_io.dart' as impl;

Future<VideoPlayerController> loadClipVideo(PlatformFile file) {
  return impl.loadClipVideo(file);
}
