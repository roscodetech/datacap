import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/media_data.dart';
import '../providers/media_provider.dart';
import '../services/upload_services.dart';
import '../widgets/media_input_form.dart';
import '../widgets/media_list_view.dart';
import 'web_camera_screen.dart';

enum CaptureMode { photo, video }

class CaptureScreen extends StatefulWidget {
  static const routeName = '/capture';
  final CaptureMode initialMode;
  final String? prefillDataset;
  final String? prefillClass;

  const CaptureScreen({
    super.key,
    this.initialMode = CaptureMode.photo,
    this.prefillDataset,
    this.prefillClass,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _classLabelController = TextEditingController();
  final TextEditingController _datasetNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialMode == CaptureMode.photo ? 0 : 1,
    );

    // Update UI when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Pre-fill with provided values or last used values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use prefill values if provided, otherwise use last used values
      if (widget.prefillDataset != null) {
        _datasetNameController.text = widget.prefillDataset!;
      } else {
        final provider = Provider.of<MediaProvider>(context, listen: false);
        if (provider.lastDatasetName != null) {
          _datasetNameController.text = provider.lastDatasetName!;
        }
      }

      if (widget.prefillClass != null) {
        _classLabelController.text = widget.prefillClass!;
      } else {
        final provider = Provider.of<MediaProvider>(context, listen: false);
        if (provider.lastClassLabel != null) {
          _classLabelController.text = provider.lastClassLabel!;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _classLabelController.dispose();
    _datasetNameController.dispose();
    super.dispose();
  }

  CaptureMode get _currentMode =>
      _tabController.index == 0 ? CaptureMode.photo : CaptureMode.video;

  Future<void> _requestPermissions() async {
    // Skip permission request on web - browser handles it
    if (kIsWeb) return;

    await [
      Permission.camera,
      Permission.storage,
      Permission.microphone,
    ].request();
  }

  Future<void> _pickMedia(ImageSource source) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in required fields', isError: true);
      return;
    }

    await _requestPermissions();

    try {
      final isVideo = _currentMode == CaptureMode.video;
      XFile? pickedFile;

      // On web with camera source, use our custom camera screen
      if (kIsWeb && source == ImageSource.camera) {
        pickedFile = await Navigator.of(context).push<XFile>(
          MaterialPageRoute(
            builder: (_) => WebCameraScreen(isVideo: isVideo),
          ),
        );
      } else if (isVideo) {
        pickedFile = await _picker.pickVideo(source: source);
      } else {
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          imageQuality: 90,
        );
      }

      if (pickedFile == null) {
        return;
      }

      String filePath;

      if (kIsWeb) {
        // On web, use the picked file path directly
        filePath = pickedFile.path;
      } else {
        // On mobile/desktop, copy to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = pickedFile.path.split('/').last;
        final savedFile =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');
        filePath = savedFile.path;
      }

      final mediaData = MediaData(
        filePath: filePath,
        classLabel: _classLabelController.text.trim(),
        datasetName: _datasetNameController.text.trim(),
        mediaType: isVideo ? MediaType.video : MediaType.photo,
        xFile: pickedFile, // Store XFile for web uploads
      );

      if (mounted) {
        Provider.of<MediaProvider>(context, listen: false).addMedia(mediaData);
        _showSnackBar(
          isVideo ? 'Video added successfully' : 'Photo added successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _uploadAllMedia() async {
    final provider = Provider.of<MediaProvider>(context, listen: false);
    final pendingMedia = provider.pendingMedia;

    if (pendingMedia.isEmpty) {
      _showSnackBar('No pending media to upload', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    final uploadService = UploadService();
    int successCount = 0;
    int failedCount = 0;

    for (var media in pendingMedia) {
      provider.updateMediaStatus(media.id, UploadStatus.uploading);

      try {
        await uploadService.uploadMedia(media);
        provider.updateMediaStatus(media.id, UploadStatus.success);
        successCount++;
      } catch (e) {
        provider.updateMediaStatus(
          media.id,
          UploadStatus.failed,
          error: e.toString(),
        );
        failedCount++;
      }
    }

    setState(() => _isUploading = false);

    if (mounted) {
      if (failedCount == 0) {
        _showSnackBar('Successfully uploaded $successCount items');
      } else {
        _showSnackBar(
          'Uploaded: $successCount, Failed: $failedCount',
          isError: failedCount > 0,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(MediaData media) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${media.classLabel}" from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<MediaProvider>(context, listen: false)
                  .removeMedia(media.id);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Data'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.photo_camera), text: 'Photos'),
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildInputSection(theme),
          const Divider(height: 1),
          Expanded(
            child: _buildMediaList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MediaInputForm(
            formKey: _formKey,
            classLabelController: _classLabelController,
            datasetNameController: _datasetNameController,
            enabled: !_isUploading,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickMedia(ImageSource.camera),
                  icon: Icon(_currentMode == CaptureMode.photo
                      ? Icons.camera_alt
                      : Icons.videocam),
                  label: Text(_currentMode == CaptureMode.photo
                      ? 'Take Photo'
                      : 'Record Video'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickMedia(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaList() {
    return Consumer<MediaProvider>(
      builder: (ctx, provider, _) {
        return TabBarView(
          controller: _tabController,
          children: [
            MediaListView(
              mediaList: provider.photos,
              emptyTitle: 'No photos yet',
              emptySubtitle: 'Take or select photos to add to your dataset',
              emptyIcon: Icons.photo_camera_outlined,
              onDelete: _confirmDelete,
            ),
            MediaListView(
              mediaList: provider.videos,
              emptyTitle: 'No videos yet',
              emptySubtitle: 'Record or select videos to add to your dataset',
              emptyIcon: Icons.videocam_outlined,
              onDelete: _confirmDelete,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Consumer<MediaProvider>(
      builder: (ctx, provider, _) {
        final pendingCount = provider.pendingCount;

        return Container(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to upload',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '$pendingCount item${pendingCount != 1 ? 's' : ''} pending',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed:
                    _isUploading || pendingCount == 0 ? null : _uploadAllMedia,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                icon: _isUploading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload All'),
              ),
            ],
          ),
        );
      },
    );
  }
}
