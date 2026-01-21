import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import '../models/media_data.dart';
import 'media_list_item.dart';
import 'empty_state.dart';

class MediaListView extends StatelessWidget {
  final List<MediaData> mediaList;
  final void Function(MediaData media)? onTap;
  final void Function(MediaData media)? onDelete;
  final void Function(MediaData media)? onRetry;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;

  const MediaListView({
    super.key,
    required this.mediaList,
    this.onTap,
    this.onDelete,
    this.onRetry,
    this.emptyTitle = 'No media yet',
    this.emptySubtitle,
    this.emptyIcon = Icons.photo_library_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaList.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        return MediaListItem(
          media: media,
          onTap: onTap != null ? () => onTap!(media) : null,
          onDelete: onDelete != null ? () => onDelete!(media) : null,
          onRetry: onRetry != null && media.status == UploadStatus.failed
              ? () => onRetry!(media)
              : null,
        );
      },
    );
  }
}
