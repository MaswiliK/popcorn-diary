import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A cached poster image. This is the primary visual object in the app —
/// keep decoration minimal so the artwork itself carries the memory.
class PosterThumbnail extends StatelessWidget {
  const PosterThumbnail({
    super.key,
    required this.imageUrl,
    this.width = 56,
    this.height = 80,
    this.borderRadius = 8,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl == null
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Icon(Icons.movie_outlined, color: AppColors.textTertiary),
    );
  }
}
