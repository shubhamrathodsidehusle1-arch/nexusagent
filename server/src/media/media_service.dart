/// NexusAgent Media Service
/// Handles images, audio, and documents

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MediaConfig {
  final int maxImageSizeMB;
  final int maxAudioSizeMB;
  final int maxDocumentSizeMB;
  final List<String> allowedImageTypes;
  final List<String> allowedAudioTypes;
  final List<String> allowedDocumentTypes;
  final String storagePath;
  final bool enableTranscription;

  MediaConfig({
    this.maxImageSizeMB = 10,
    this.maxAudioSizeMB = 50,
    this.maxDocumentSizeMB = 25,
    this.allowedImageTypes = const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    this.allowedAudioTypes = const ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
    this.allowedDocumentTypes = const ['pdf', 'doc', 'docx', 'txt', 'md', 'csv'],
    this.storagePath = '/tmp/nexusagent/media',
    this.enableTranscription = false,
  });
}

enum MediaType {
  image,
  audio,
  document,
  unknown,
}

class MediaFile {
  final String id;
  final String filename;
  final MediaType type;
  final String mimeType;
  final int size;
  final String path;
  final DateTime uploadedAt;
  final String? url;
  final Map<String, dynamic>? metadata;

  MediaFile({
    required this.id,
    required this.filename,
    required this.type,
    required this.mimeType,
    required this.size,
    required this.path,
    required this.uploadedAt,
    this.url,
    this.metadata,
  });
}

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  MediaConfig _config = MediaConfig();
  final Map<String, MediaFile> _files = {};

  /// Initialize
  void initialize(MediaConfig config) {
    _config = config;
    _ensureStorageDir();
    print('Media service initialized');
  }

  void _ensureStorageDir() {
    final dir = Directory(_config.storagePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Upload from URL
  Future<MediaFile?> uploadFromUrl(String url, {String? filename}) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode != 200) {
        return null;
      }

      // Determine filename
      filename ??= url.split('/').last;
      
      // Determine type
      final ext = filename.split('.').last.toLowerCase();
      final type = _getMediaType(ext);
      
      if (type == MediaType.unknown) {
        return null;
      }

      // Check size
      final size = response.bodyBytes.length;
      final maxSize = _getMaxSize(type);
      if (size > maxSize * 1024 * 1024) {
        return null;
      }

      // Save file
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '$_config.storagePath/$id.$ext';
      await File(path).writeAsBytes(response.bodyBytes);

      final mediaFile = MediaFile(
        id: id,
        filename: filename,
        type: type,
        mimeType: _getMimeType(ext),
        size: size,
        path: path,
        uploadedAt: DateTime.now(),
      );

      _files[id] = mediaFile;
      return mediaFile;
    } catch (e) {
      print('Media upload error: $e');
      return null;
    }
  }

  /// Upload from bytes
  Future<MediaFile?> uploadFromBytes(Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final type = _getMediaType(ext);

    if (type == MediaType.unknown) {
      return null;
    }

    // Check size
    final size = bytes.length;
    final maxSize = _getMaxSize(type);
    if (size > maxSize * 1024 * 1024) {
      return null;
    }

    // Save file
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '$_config.storagePath/$id.$ext';
    await File(path).writeAsBytes(bytes);

    final mediaFile = MediaFile(
      id: id,
      filename: filename,
      type: type,
      mimeType: _getMimeType(ext),
      size: size,
      path: path,
      uploadedAt: DateTime.now(),
    );

    _files[id] = mediaFile;
    return mediaFile;
  }

  /// Transcribe audio (mock)
  Future<String?> transcribeAudio(String mediaId) async {
    if (!_config.enableTranscription) {
      return null;
    }

    // In production, would use Whisper or similar
    return 'Transcription not implemented';
  }

  /// Get media file
  MediaFile? getMedia(String id) => _files[id];

  /// Delete media
  void deleteMedia(String id) {
    final file = _files[id];
    if (file != null) {
      try {
        File(file.path).deleteSync();
      } catch (e) {
        // Ignore
      }
      _files.remove(id);
    }
  }

  /// List media
  List<MediaFile> listMedia({MediaType? type}) {
    if (type == null) return _files.values.toList();
    return _files.values.where((f) => f.type == type).toList();
  }

  MediaType _getMediaType(String ext) {
    if (_config.allowedImageTypes.contains(ext)) return MediaType.image;
    if (_config.allowedAudioTypes.contains(ext)) return MediaType.audio;
    if (_config.allowedDocumentTypes.contains(ext)) return MediaType.document;
    return MediaType.unknown;
  }

  String _getMimeType(String ext) {
    final types = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'csv': 'text/csv',
    };
    return types[ext] ?? 'application/octet-stream';
  }

  int _getMaxSize(MediaType type) {
    switch (type) {
      case MediaType.image: return _config.maxImageSizeMB;
      case MediaType.audio: return _config.maxAudioSizeMB;
      case MediaType.document: return _config.maxDocumentSizeMB;
      case MediaType.unknown: return 0;
    }
  }
}
