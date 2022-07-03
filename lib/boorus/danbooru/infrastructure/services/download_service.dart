// Dart imports:
import 'dart:isolate';
import 'dart:ui';

// Package imports:
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/core/application/download/i_download_service.dart';
import 'package:boorusama/core/domain/file_name_generator.dart';

class DownloadService implements IDownloadService<Post> {
  DownloadService({
    required FileNameGenerator fileNameGenerator,
  }) : _fileNameGenerator = fileNameGenerator;

  final FileNameGenerator _fileNameGenerator;
  final ReceivePort _port = ReceivePort();
  String _savedDir = '';

  @override
  Future<void> download(
    Post downloadable, {
    String? path,
  }) async {
    final fileName = _fileNameGenerator.generateFor(downloadable);
    await FlutterDownloader.enqueue(
      saveInPublicStorage: true,
      url: downloadable.downloadUrl,
      fileName: fileName,
      savedDir: _savedDir,
    );
  }

  Future<void> _prepare() async {
    // This won't be used.
    _savedDir = (await getTemporaryDirectory()).path;
  }

  void _bindBackgroundIsolate() {
    final bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @override
  Future<void> init() async {
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    await _prepare();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
  }
}
