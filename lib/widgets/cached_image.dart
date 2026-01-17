import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lahv/utils/my_cache_manager.dart';

class CachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      cacheManager: MyCacheManager.instance,
      fit: fit,
      height: height,
      width: width,
      placeholder: (_, __) => Container(
        color: Colors.black,
      ),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
