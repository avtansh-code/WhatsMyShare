import 'package:flutter/material.dart';

import '../services/logging_service.dart';

/// A CircleAvatar that loads images from a network URL with proper error handling.
/// 
/// This widget gracefully handles cases where the network image fails to load,
/// such as invalid image data, expired tokens, network errors, etc.
class NetworkAvatar extends StatelessWidget {
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

  const NetworkAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.child,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? 
        Theme.of(context).colorScheme.primaryContainer;
    final fallbackChild = child ?? 
        Icon(
          Icons.person,
          size: radius,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        );

    // If no image URL, show fallback
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: fallbackChild,
      );
    }

    // Use ClipOval with Image.network for better error handling
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Loading placeholder
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: bgColor,
              child: Center(
                child: SizedBox(
                  width: radius * 0.8,
                  height: radius * 0.8,
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
            LoggingService().warning(
              'Failed to load network image',
              tag: LogTags.ui,
              data: {
                'url': imageUrl,
                'error': error.toString(),
              },
            );
            onError?.call();
            return Container(
              width: radius * 2,
              height: radius * 2,
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
