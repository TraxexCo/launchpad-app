import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/profile_image_service.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.size,
    required this.fallbackLabel,
    this.storagePath,
    this.fallbackIcon,
    this.onTap,
    this.square = false,
    this.showEditBadge = false,
  });

  final double size;
  final String fallbackLabel;
  final String? storagePath;
  final IconData? fallbackIcon;
  final VoidCallback? onTap;
  final bool square;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    final path = storagePath?.trim() ?? '';
    final url = path.isEmpty ? '' : ProfileImageService().publicUrl(path);
    final radius = square ? size * .24 : size / 2;
    final decodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(48, 512);
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderHigh),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? _fallback()
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: decodeSize,
              memCacheHeight: decodeSize,
              maxWidthDiskCache: decodeSize,
              maxHeightDiskCache: decodeSize,
              fadeInDuration: const Duration(milliseconds: 140),
              placeholder: (_, _) => _fallback(),
              errorWidget: (_, _, _) => _fallback(),
            ),
    );

    final result = Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (showEditBadge)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: AppColors.studentPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 12,
                color: AppColors.ink,
              ),
            ),
          ),
      ],
    );
    return Semantics(
      button: onTap != null,
      label: onTap == null ? 'Profile photo' : 'Change profile photo',
      child: onTap == null
          ? result
          : GestureDetector(onTap: onTap, child: result),
    );
  }

  Widget _fallback() {
    if (fallbackIcon != null) {
      return Icon(fallbackIcon, color: AppColors.textPrimary, size: size * .42);
    }
    return Center(
      child: Text(
        fallbackLabel.isEmpty ? 'LP' : fallbackLabel,
        style: TextStyle(
          fontSize: size * .28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
