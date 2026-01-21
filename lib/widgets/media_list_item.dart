import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/media_data.dart';

class MediaListItem extends StatelessWidget {
  final MediaData media;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const MediaListItem({
    super.key,
    required this.media,
    this.onTap,
    this.onDelete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: AppSpacing.cardPaddingCompact,
          child: Row(
            children: [
              _buildThumbnail(isDark),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildInfo(theme, isDark),
              ),
              _buildActions(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    return Container(
      width: AppSpacing.thumbnailMd,
      height: AppSpacing.thumbnailMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: media.isVideo
          ? _buildVideoThumbnail(isDark)
          : _buildImageThumbnail(),
    );
  }

  Widget _buildImageThumbnail() {
    // On web, use Image.network with blob URL
    // On mobile/desktop, use Image.file
    if (kIsWeb) {
      // Web platform - use network image with blob URL
      if (media.filePath.isNotEmpty) {
        return Image.network(
          media.filePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.image),
        );
      }
      return _buildPlaceholder(Icons.image);
    } else {
      // Mobile/Desktop platform - use file image
      final file = File(media.filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.image),
        );
      }
      return _buildPlaceholder(Icons.image);
    }
  }

  Widget _buildVideoThumbnail(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.outlineLight,
        ),
        Icon(
          Icons.videocam,
          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariantLight,
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Center(
      child: Icon(
        icon,
        color: AppColors.onSurfaceVariantLight,
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          media.classLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          media.datasetName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.onSurfaceVariantDark
                : AppColors.onSurfaceVariantLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildStatusChip(isDark),
      ],
    );
  }

  Widget _buildStatusChip(bool isDark) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (media.status) {
      case UploadStatus.pending:
        backgroundColor = AppColors.statusPending.withOpacity(0.15);
        textColor = AppColors.statusPending;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      case UploadStatus.uploading:
        backgroundColor = AppColors.statusUploading.withOpacity(0.15);
        textColor = AppColors.statusUploading;
        label = '${(media.uploadProgress * 100).toInt()}%';
        icon = Icons.cloud_upload;
        break;
      case UploadStatus.success:
        backgroundColor = AppColors.statusSuccess.withOpacity(0.15);
        textColor = AppColors.statusSuccess;
        label = 'Uploaded';
        icon = Icons.check_circle;
        break;
      case UploadStatus.failed:
        backgroundColor = AppColors.statusFailed.withOpacity(0.15);
        textColor = AppColors.statusFailed;
        label = 'Failed';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (media.status == UploadStatus.failed && onRetry != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRetry,
            tooltip: 'Retry upload',
            color: AppColors.primary,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Remove',
            color: AppColors.error,
          ),
      ],
    );
  }
}
