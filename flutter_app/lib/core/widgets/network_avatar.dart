import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/encryption_service.dart';
import '../services/logging_service.dart';

/// A CircleAvatar that loads images from a network URL with proper error handling.
/// 
/// This widget gracefully handles cases where the network image fails to load,
/// such as invalid image data, expired tokens, network errors, etc.
/// 
/// Supports encrypted images when an [encryptionService] is provided.
class NetworkAvatar extends StatefulWidget {
  /// Clear cached image for a specific URL
  static void clearCacheForUrl(String url) {
    _NetworkAvatarState._decryptedCache.remove(url);
  }

  /// Clear all cached decrypted images
  static void clearAllCache() {
    _NetworkAvatarState._decryptedCache.clear();
  }

  /// The URL of the image to load
  final String? imageUrl;

  /// The radius of the avatar
  final double radius;

  /// Background color when no image is available
  final Color? backgroundColor;

  /// The fallback widget to show when image is not available or fails to load.
  /// Typically this would be initials or an icon.
  final Widget? child;

  /// Optional callback when image fails to load
  final VoidCallback? onError;

  /// Optional encryption service for decrypting encrypted images.
  /// When provided, images will be downloaded and decrypted before display.
  final EncryptionService? encryptionService;

  const NetworkAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.child,
    this.onError,
    this.encryptionService,
  });

  @override
  State<NetworkAvatar> createState() => _NetworkAvatarState();
}

class _NetworkAvatarState extends State<NetworkAvatar> {
  final LoggingService _log = LoggingService();
  
  Uint8List? _decryptedImageData;
  bool _isLoading = false;
  bool _hasError = false;
  String? _lastLoadedUrl;

  // Static cache for decrypted images to avoid re-decryption
  static final Map<String, Uint8List> _decryptedCache = {};
  static const int _maxCacheSize = 50;

  @override
  void initState() {
    super.initState();
    _loadImageIfNeeded();
  }

  @override
  void didUpdateWidget(NetworkAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImageIfNeeded();
    }
  }

  void _loadImageIfNeeded() {
    if (widget.encryptionService != null && 
        widget.imageUrl != null && 
        widget.imageUrl!.isNotEmpty &&
        widget.imageUrl != _lastLoadedUrl) {
      _loadAndDecryptImage();
    }
  }

  Future<void> _loadAndDecryptImage() async {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check cache first
      if (_decryptedCache.containsKey(url)) {
        _log.debug('Using cached decrypted avatar image', tag: LogTags.encryption);
        if (mounted) {
          setState(() {
            _decryptedImageData = _decryptedCache[url];
            _isLoading = false;
            _lastLoadedUrl = url;
          });
        }
        return;
      }

      // Download the encrypted data
      _log.debug('Downloading encrypted avatar image', tag: LogTags.encryption, data: {'url': url});
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      // Decrypt the data
      _log.debug('Decrypting avatar image', tag: LogTags.encryption);
      final decryptedData = await widget.encryptionService!.decryptBytes(response.bodyBytes);

      // Add to memory cache (with size limit)
      if (_decryptedCache.length >= _maxCacheSize) {
        _decryptedCache.remove(_decryptedCache.keys.first);
      }
      _decryptedCache[url] = decryptedData;

      if (mounted) {
        setState(() {
          _decryptedImageData = decryptedData;
          _isLoading = false;
          _lastLoadedUrl = url;
        });
      }
    } catch (e) {
      _log.warning(
        'Failed to load encrypted avatar image',
        tag: LogTags.encryption,
        data: {'url': url, 'error': e.toString()},
      );
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        widget.onError?.call();
      }
    }
  }

  /// Clear cached image for a specific URL
  static void clearCacheForUrl(String url) {
    _decryptedCache.remove(url);
  }

  /// Clear all cached decrypted images
  static void clearAllCache() {
    _decryptedCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? 
        Theme.of(context).colorScheme.primaryContainer;
    final fallbackChild = widget.child ?? 
        Icon(
          Icons.person,
          size: widget.radius,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        );

    // If no image URL, show fallback
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        child: fallbackChild,
      );
    }

    // For encrypted images, use the decrypted data
    if (widget.encryptionService != null) {
      return _buildEncryptedAvatar(bgColor, fallbackChild);
    }

    // For non-encrypted images, use Image.network
    return _buildNetworkAvatar(bgColor, fallbackChild);
  }

  Widget _buildEncryptedAvatar(Color bgColor, Widget fallbackChild) {
    if (_isLoading) {
      return SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: CircleAvatar(
          radius: widget.radius,
          backgroundColor: bgColor,
          child: SizedBox(
            width: widget.radius * 0.8,
            height: widget.radius * 0.8,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasError || _decryptedImageData == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        child: fallbackChild,
      );
    }

    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: ClipOval(
        child: Image.memory(
          _decryptedImageData!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            _log.warning(
              'Failed to display decrypted image',
              tag: LogTags.ui,
              data: {'error': error.toString()},
            );
            return Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: fallbackChild),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNetworkAvatar(Color bgColor, Widget fallbackChild) {
    // Use ClipOval with Image.network for better error handling
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: ClipOval(
        child: Image.network(
          widget.imageUrl!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          // Loading placeholder
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              color: bgColor,
              child: Center(
                child: SizedBox(
                  width: widget.radius * 0.8,
                  height: widget.radius * 0.8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          // Error handling - show fallback on any image loading error
          errorBuilder: (context, error, stackTrace) {
            _log.warning(
              'Failed to load network image',
              tag: LogTags.ui,
              data: {
                'url': widget.imageUrl,
                'error': error.toString(),
              },
            );
            widget.onError?.call();
            return Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: fallbackChild),
            );
          },
        ),
      ),
    );
  }
}

/// A network image widget with proper error handling for non-circular images.
/// 
/// This widget gracefully handles cases where the network image fails to load,
/// such as invalid image data, expired tokens, network errors, etc.
class SafeNetworkImage extends StatelessWidget {
  /// The URL of the image to load
  final String? imageUrl;

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

  /// Optional callback when image fails to load
  final VoidCallback? onError;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    // If no image URL, show error widget or default
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(context);
    }

    Widget imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return placeholder ?? _buildPlaceholder(context, loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        LoggingService().warning(
          'Failed to load network image',
          tag: LogTags.ui,
          data: {
            'url': imageUrl,
            'error': error.toString(),
          },
        );
        onError?.call();
        return _buildErrorWidget(context);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context, ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
  }
}
