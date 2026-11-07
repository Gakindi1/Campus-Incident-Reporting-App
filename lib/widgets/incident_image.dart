import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/status_style.dart';
import '../models/incident_enums.dart';

/// Shows an incident photo, falling back to a tinted category icon when the
/// report has no photo or the image fails to load.
class IncidentImage extends StatelessWidget {
  const IncidentImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.size,
    this.height,
    this.borderRadius = 14,
  });

  final String? imageUrl;
  final IncidentCategory category;

  /// Square size; ignored when [height] is set (full-width image).
  final double? size;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final width = height != null ? double.infinity : size;
    final h = height ?? size;
    final placeholder = Container(
      width: width,
      height: h,
      color: category.color.withValues(alpha: 0.12),
      child: Icon(
        category.icon,
        color: category.color,
        size: (h ?? 48) * 0.4,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              width: width,
              height: h,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}
