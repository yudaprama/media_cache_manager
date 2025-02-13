part of '../media_cache_manager.dart';

class DownloadMediaBuilderController {
  DownloadMediaBuilderController({
    required this.url,
    required DownloadMediaSnapshot snapshot,
    required Function(DownloadMediaSnapshot) onSnapshotChanged,
    required this.encryptionPassword,
    required this.filename,
  }) {
    _onSnapshotChanged = onSnapshotChanged;
    _snapshot = snapshot;
  }

  final String url;

  final String? filename;

  final String? encryptionPassword;

  /// When snapshot changes this function will called and give you the new snapshot
  late final Function(DownloadMediaSnapshot) _onSnapshotChanged;

  /// Provide us a 3 Variable
  /// 1 - Status : It's the status of the process (Initial, Success, Loading, Error, Canceled, Encrypting, Decrypting).
  /// 2 - Progress : The progress if the file is downloading.
  /// 3 - FilePath : When Status is Success the FilePath won't be null;
  late final DownloadMediaSnapshot _snapshot;

  /// Downloader Instance
  Downloader? _downloader;

  Encryptor _encryptor = Encryptor.instance;

  /// Try to get file path from cache,
  /// If it's not exists it will download the file and cache it.
  Future<void> getFile() async {
    if (encryptionPassword != null) {
      _encryptor = Encryptor();
      await _encryptor.init();
      _encryptor.setPassword(encryptionPassword!);
    }
    _snapshot.filePath = null;
    _snapshot.status = DownloadMediaStatus.loading;
    _snapshot.progress = null;
    _onSnapshotChanged(_snapshot);
    String? filePath = DownloadCacheManager.instance.getCachedFilePath(url);
    if (filePath != null) {
      _snapshot.status = DownloadMediaStatus.decrypting;
      _onSnapshotChanged(_snapshot);
      final decryptedFilePath = await _encryptor.decrypt(filePath);
      if (decryptedFilePath != null) {
        _snapshot.filePath = decryptedFilePath;
        _snapshot.status = DownloadMediaStatus.success;
        _onSnapshotChanged(_snapshot);
        return;
      }
    }
    _downloader = Downloader(url: url);
    filePath = await _downloader!.download(
      onProgress: (progress, total) {
        _snapshot.status = DownloadMediaStatus.loading;
        _onSnapshotChanged(_snapshot..progress = (progress / total));
      },
      filename: filename,
    );
    if (filePath != null) {
      _snapshot.status = DownloadMediaStatus.encrypting;
      _onSnapshotChanged(_snapshot);
      final encryptedFilePath = await _encryptor.encrypt(filePath);
      _snapshot.filePath = filePath;
      _snapshot.status = DownloadMediaStatus.success;
      _onSnapshotChanged(_snapshot);

      /// Caching FilePath
      await DownloadCacheManager.instance.cacheFilePath(url: url, path: encryptedFilePath!);
    } else {
      if (_snapshot.status != DownloadMediaStatus.canceled) {
        _onSnapshotChanged(_snapshot..status = DownloadMediaStatus.error);
      }
    }
  }

  /// Cancel Downloading file if download status is loading otherwise nothing will happen
  Future<void> cancelDownload() async {
    if (_snapshot.status == DownloadMediaStatus.loading) {
      await _downloader?.cancel();
      _snapshot.status = DownloadMediaStatus.canceled;
      _onSnapshotChanged(_snapshot);
    }
  }

  /// Retry to get a downloaded file only if the status is canceled or end with error.
  Future<void> retry() async {
    if (_snapshot.status == DownloadMediaStatus.canceled ||
        _snapshot.status == DownloadMediaStatus.error) {
      _snapshot.status = DownloadMediaStatus.loading;
      _snapshot.progress = null;
      _onSnapshotChanged(_snapshot);
      _downloader = Downloader(url: url);
      getFile();
    }
  }
}
