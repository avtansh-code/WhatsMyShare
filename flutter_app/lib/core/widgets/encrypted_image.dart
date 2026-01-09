import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../services/encryption_service.dart';
import '../services/logging_service.dart';

/// A widget that displays an encrypted image from a URL
/// Downloads the encrypted data, decrypts it on device, and displays the image
class EncryptedImage extends StatefulWidget {
  /// The URL of the encrypted image
  final String imageUrl;

  /// The encryption service to use for decryption
  final EncryptionService encryptionService;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// How the image should fit within its bounds
  final BoxFit fit;

  /// Widget to show while loading
  final Widget? placeholder;

  /// Widget to show on error
  final Widget? errorWidget;

  /// Border radius for the image
  final BorderRadius? borderRadius;

  /// Cache key for the image (defaults to URL hash)
  final String? cacheKey;

  const EncryptedImage({
    super.key,
    required this.imageUrl,
    required this.encryptionService,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheKey,
  });

  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  final LoggingService _log = LoggingService();

  Uint8List? _decryptedImageData;
  bool _isLoading = true;
  String? _error;

  // Cache for decrypted images to avoid re-decryption
  static final Map<String, Uint8List> _decryptedCache = {};
  static const int _maxCacheSize = 50;

  @override
  void initState() {
    super.initState();
    _loadAndDecryptImage();
  }

  @override
  void didUpdateWidget(EncryptedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadAndDecryptImage();
    }
  }

  String get _cacheKey =>
      widget.cacheKey ?? widget.imageUrl.hashCode.toString();

  Future<void> _loadAndDecryptImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check cache first
      if (_decryptedCache.containsKey(_cacheKey)) {
        _log.debug('Using cached decrypted image', tag: LogTags.encryption);
        setState(() {
          _decryptedImageData = _decryptedCache[_cacheKey];
          _isLoading = false;
        });
        return;
      }

      // Check if we have a local cached file
      final localFile = await _getLocalCacheFile();
      Uint8List encryptedData;

      if (await localFile.exists()) {
        _log.debug('Loading from local cache', tag: LogTags.encryption);
        encryptedData = await localFile.readAsBytes();
      } else {
        // Download the encrypted data
        _log.debug('Downloading encrypted image', tag: LogTags.encryption);
        final response = await http.get(Uri.parse(widget.imageUrl));

        if (response.statusCode != 200) {
          throw Exception('Failed to download image: ${response.statusCode}');
        }

        encryptedData = response.bodyBytes;

        // Cache the encrypted file locally
        await localFile.writeAsBytes(encryptedData);
      }

      // Decrypt the data
      _log.debug('Decrypting image', tag: LogTags.encryption);
      final decryptedData = await widget.encryptionService.decryptBytes(
        encryptedData,
      );

      // Add to memory cache (with size limit)
      if (_decryptedCache.length >= _maxCacheSize) {
        _decryptedCache.remove(_decryptedCache.keys.first);
      }
      _decryptedCache[_cacheKey] = decryptedData;

      if (mounted) {
        setState(() {
          _decryptedImageData = decryptedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      _log.error(
        'Failed to load encrypted image',
        tag: LogTags.encryption,
        data: {'error': e.toString()},
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<File> _getLocalCacheFile() async {
    final cacheDir = await getTemporaryDirectory();
    final encryptedCacheDir = Directory('${cacheDir.path}/encrypted_images');
    if (!await encryptedCacheDir.exists()) {
      await encryptedCacheDir.create(recursive: true);
    }
    return File('${encryptedCacheDir.path}/$_cacheKey.enc');
  }

  /// Clear the local cache for this image
  Future<void> clearCache() async {
    _decryptedCache.remove(_cacheKey);
    final localFile = await _getLocalCacheFile();
    if (await localFile.exists()) {
      await localFile.delete();
    }
  }

  /// Clear all cached images
  static Future<void> clearAllCache() async {
    _decryptedCache.clear();
    final cacheDir = await getTemporaryDirectory();
    final encryptedCacheDir = Directory('${cacheDir.path}/encrypted_images');
    if (await encryptedCacheDir.exists()) {
      await encryptedCacheDir.delete(recursive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (_isLoading) {
      imageWidget =
          widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    } else if (_error != null) {
      imageWidget =
          widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
    } else if (_decryptedImageData != null) {
      imageWidget = Image.memory(
        _decryptedImageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
        },
      );
    } else {
      imageWidget =
          widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}

/// A circular encrypted image widget, useful for avatars
class EncryptedCircleAvatar extends StatelessWidget {
  /// The URL of the encrypted image
  final String? imageUrl;

  /// The encryption service to use for decryption
  final EncryptionService encryptionService;

  /// Radius of the circle
  final double radius;

  /// Background color when no image
  final Color? backgroundColor;

  /// Fallback widget when no image (e.g., initials)
  final Widget? child;

  const EncryptedCircleAvatar({
    super.key,
    this.imageUrl,
    required this.encryptionService,
    this.radius = 20,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor:
            backgroundColor ??
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: child,
      );
    }

    return ClipOval(
      child: EncryptedImage(
        imageUrl: imageUrl!,
        encryptionService: encryptionService,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[200],
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: CircleAvatar(
          radius: radius,
          backgroundColor:
              backgroundColor ??
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: child ?? const Icon(Icons.person, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Provider for encrypted images that handles caching and decryption
class EncryptedImageProvider {
  final EncryptionService _encryptionService;
  final LoggingService _log = LoggingService();

  EncryptedImageProvider(this._encryptionService);

  /// Download and decrypt an image, returning the decrypted bytes
  Future<Uint8List?> getDecryptedImage(String imageUrl) async {
    try {
      // Download the encrypted data
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      // Decrypt and return
      return await _encryptionService.decryptBytes(response.bodyBytes);
    } catch (e) {
      _log.error(
        'Failed to get decrypted image',
        tag: LogTags.encryption,
        data: {'url': imageUrl, 'error': e.toString()},
      );
      return null;
    }
  }

  /// Save a decrypted image to a temporary file
  Future<File?> saveDecryptedImageToTemp(
    String imageUrl,
    String filename,
  ) async {
    try {
      final decryptedData = await getDecryptedImage(imageUrl);
      if (decryptedData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(decryptedData);
      return file;
    } catch (e) {
      _log.error(
        'Failed to save decrypted image',
        tag: LogTags.encryption,
        data: {'error': e.toString()},
      );
      return null;
    }
  }
}
