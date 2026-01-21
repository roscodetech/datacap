import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/upload_services.dart';
import '../widgets/video_thumbnail.dart';
import 'video_player_screen.dart';
import 'capture_screen.dart';

class DatasetBrowserScreen extends StatefulWidget {
  final List<StorageItem> allItems;
  final VoidCallback? onRefresh;

  const DatasetBrowserScreen({
    super.key,
    required this.allItems,
    this.onRefresh,
  });

  @override
  State<DatasetBrowserScreen> createState() => _DatasetBrowserScreenState();
}

class _DatasetBrowserScreenState extends State<DatasetBrowserScreen> {
  final UploadService _uploadService = UploadService();
  String? _selectedDataset;
  String? _selectedClass;
  bool _isProcessing = false;

  // Get unique datasets
  Map<String, DatasetInfo> get _datasets {
    final Map<String, DatasetInfo> datasets = {};

    for (final item in widget.allItems) {
      final datasetName = item.datasetName;
      if (datasetName == null) continue;

      if (!datasets.containsKey(datasetName)) {
        datasets[datasetName] = DatasetInfo(
          name: datasetName,
          classes: [],
          photoCount: 0,
          videoCount: 0,
        );
      }

      final classLabel = item.classLabel;
      if (classLabel != null) {
        final existing = datasets[datasetName]!;
        final classes = List<String>.from(existing.classes);
        if (!classes.contains(classLabel)) {
          classes.add(classLabel);
        }
        datasets[datasetName] = DatasetInfo(
          name: datasetName,
          classes: classes,
          photoCount: existing.photoCount + (item.isImage ? 1 : 0),
          videoCount: existing.videoCount + (item.isVideo ? 1 : 0),
        );
      }
    }

    return datasets;
  }

  // Get classes for selected dataset
  List<ClassInfo> get _classes {
    if (_selectedDataset == null) return [];

    final Map<String, ClassInfo> classes = {};

    for (final item in widget.allItems) {
      if (item.datasetName != _selectedDataset) continue;

      final classLabel = item.classLabel;
      if (classLabel == null) continue;

      if (!classes.containsKey(classLabel)) {
        classes[classLabel] = ClassInfo(
          name: classLabel,
          photoCount: 0,
          videoCount: 0,
        );
      }

      final existing = classes[classLabel]!;
      classes[classLabel] = ClassInfo(
        name: classLabel,
        photoCount: existing.photoCount + (item.isImage ? 1 : 0),
        videoCount: existing.videoCount + (item.isVideo ? 1 : 0),
      );
    }

    return classes.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get items for selected dataset and class
  List<StorageItem> get _filteredItems {
    return widget.allItems.where((item) {
      if (_selectedDataset != null && item.datasetName != _selectedDataset) {
        return false;
      }
      if (_selectedClass != null && item.classLabel != _selectedClass) {
        return false;
      }
      return true;
    }).toList();
  }

  void _selectDataset(String dataset) {
    setState(() {
      _selectedDataset = dataset;
      _selectedClass = null;
    });
  }

  void _selectClass(String classLabel) {
    setState(() {
      _selectedClass = classLabel;
    });
  }

  void _goBack() {
    setState(() {
      if (_selectedClass != null) {
        _selectedClass = null;
      } else if (_selectedDataset != null) {
        _selectedDataset = null;
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // Quick add - navigate to capture screen with prefilled data
  void _quickAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          initialMode: CaptureMode.photo,
          prefillDataset: _selectedDataset,
          prefillClass: _selectedClass,
        ),
      ),
    ).then((_) => widget.onRefresh?.call());
  }

  // Delete dataset
  Future<void> _deleteDataset(String datasetName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Dataset'),
        content: Text(
          'Are you sure you want to delete "$datasetName" and ALL its contents?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final count = await _uploadService.deleteAllInPath('datasets/$datasetName');
        _showSnackBar('Deleted $count items from "$datasetName"');
        widget.onRefresh?.call();
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Delete class
  Future<void> _deleteClass(String className) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
          'Are you sure you want to delete "$className" and ALL its contents?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final count = await _uploadService.deleteAllInPath(
          'datasets/$_selectedDataset/$className',
        );
        _showSnackBar('Deleted $count items from "$className"');
        widget.onRefresh?.call();
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Rename dataset
  Future<void> _renameDataset(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Dataset'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      setState(() => _isProcessing = true);
      try {
        final count = await _uploadService.renamePath(
          'datasets/$oldName',
          'datasets/$newName',
        );
        _showSnackBar('Renamed "$oldName" to "$newName" ($count items)');
        if (_selectedDataset == oldName) {
          _selectedDataset = newName;
        }
        widget.onRefresh?.call();
      } catch (e) {
        _showSnackBar('Failed to rename: $e', isError: true);
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Rename class
  Future<void> _renameClass(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Class'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      setState(() => _isProcessing = true);
      try {
        final count = await _uploadService.renamePath(
          'datasets/$_selectedDataset/$oldName',
          'datasets/$_selectedDataset/$newName',
        );
        _showSnackBar('Renamed "$oldName" to "$newName" ($count items)');
        if (_selectedClass == oldName) {
          _selectedClass = newName;
        }
        widget.onRefresh?.call();
      } catch (e) {
        _showSnackBar('Failed to rename: $e', isError: true);
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Delete single media item
  Future<void> _deleteMedia(StorageItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.name}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _uploadService.deleteByUrl(item.downloadUrl);
        _showSnackBar('Deleted "${item.name}"');
        widget.onRefresh?.call();
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Processing...'),
          ],
        ),
      );
    }

    if (_selectedClass != null) {
      return _ClassMediaView(
        datasetName: _selectedDataset!,
        className: _selectedClass!,
        items: _filteredItems,
        onBack: _goBack,
        onQuickAdd: _quickAdd,
        onDeleteMedia: _deleteMedia,
      );
    }

    if (_selectedDataset != null) {
      return _ClassListView(
        datasetName: _selectedDataset!,
        classes: _classes,
        onSelectClass: _selectClass,
        onBack: _goBack,
        onQuickAdd: _quickAdd,
        onRenameClass: _renameClass,
        onDeleteClass: _deleteClass,
      );
    }

    return _DatasetListView(
      datasets: _datasets,
      onSelectDataset: _selectDataset,
      onQuickAdd: _quickAdd,
      onRenameDataset: _renameDataset,
      onDeleteDataset: _deleteDataset,
    );
  }
}

class _DatasetListView extends StatelessWidget {
  final Map<String, DatasetInfo> datasets;
  final Function(String) onSelectDataset;
  final VoidCallback onQuickAdd;
  final Function(String) onRenameDataset;
  final Function(String) onDeleteDataset;

  const _DatasetListView({
    required this.datasets,
    required this.onSelectDataset,
    required this.onQuickAdd,
    required this.onRenameDataset,
    required this.onDeleteDataset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final datasetList = datasets.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      body: datasetList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No datasets found',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Upload media to see your datasets here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: AppSpacing.screenPadding,
              itemCount: datasetList.length,
              itemBuilder: (context, index) {
                final dataset = datasetList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      dataset.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${dataset.classes.length} classes • ${dataset.photoCount} photos • ${dataset.videoCount} videos',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          onRenameDataset(dataset.name);
                        } else if (value == 'delete') {
                          onDeleteDataset(dataset.name);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => onSelectDataset(dataset.name),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onQuickAdd,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Media'),
      ),
    );
  }
}

class _ClassListView extends StatelessWidget {
  final String datasetName;
  final List<ClassInfo> classes;
  final Function(String) onSelectClass;
  final VoidCallback onBack;
  final VoidCallback onQuickAdd;
  final Function(String) onRenameClass;
  final Function(String) onDeleteClass;

  const _ClassListView({
    required this.datasetName,
    required this.classes,
    required this.onSelectClass,
    required this.onBack,
    required this.onQuickAdd,
    required this.onRenameClass,
    required this.onDeleteClass,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.folder, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    datasetName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Class list
          Expanded(
            child: classes.isEmpty
                ? Center(
                    child: Text(
                      'No classes found in this dataset',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: AppSpacing.screenPadding,
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classInfo = classes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.label,
                              color: AppColors.secondary,
                            ),
                          ),
                          title: Text(
                            classInfo.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${classInfo.photoCount} photos • ${classInfo.videoCount} videos',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'rename') {
                                onRenameClass(classInfo.name);
                              } else if (value == 'delete') {
                                onDeleteClass(classInfo.name);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Rename'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => onSelectClass(classInfo.name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onQuickAdd,
        icon: const Icon(Icons.add_a_photo),
        label: Text('Add to $datasetName'),
      ),
    );
  }
}

class _ClassMediaView extends StatefulWidget {
  final String datasetName;
  final String className;
  final List<StorageItem> items;
  final VoidCallback onBack;
  final VoidCallback onQuickAdd;
  final Function(StorageItem) onDeleteMedia;

  const _ClassMediaView({
    required this.datasetName,
    required this.className,
    required this.items,
    required this.onBack,
    required this.onQuickAdd,
    required this.onDeleteMedia,
  });

  @override
  State<_ClassMediaView> createState() => _ClassMediaViewState();
}

class _ClassMediaViewState extends State<_ClassMediaView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<StorageItem> get _photos =>
      widget.items.where((i) => i.isImage).toList();
  List<StorageItem> get _videos =>
      widget.items.where((i) => i.isVideo).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.label, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.className,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.datasetName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All (${widget.items.length})'),
              Tab(text: 'Photos (${_photos.length})'),
              Tab(text: 'Videos (${_videos.length})'),
            ],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMediaGrid(widget.items),
                _buildMediaGrid(_photos),
                _buildMediaGrid(_videos),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onQuickAdd,
        icon: const Icon(Icons.add_a_photo),
        label: Text('Add to ${widget.className}'),
      ),
    );
  }

  Widget _buildMediaGrid(List<StorageItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No media found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return GridView.builder(
      padding: AppSpacing.screenPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaGridItem(
          item: item,
          onTap: () => _showMediaDetail(item),
          onDelete: () => widget.onDeleteMedia(item),
        );
      },
    );
  }

  void _showMediaDetail(StorageItem item) {
    if (item.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoUrl: item.downloadUrl,
            title: item.name,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _ImageDetailSheet(item: item),
      );
    }
  }
}

class _MediaGridItem extends StatelessWidget {
  final StorageItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MediaGridItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.isImage)
              Image.network(
                item.downloadUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image, size: 48));
                },
              )
            else
              IgnorePointer(
                child: VideoThumbnail(
                  videoUrl: item.downloadUrl,
                  fit: BoxFit.cover,
                ),
              ),
            if (item.isVideo)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 16),
                      SizedBox(width: 2),
                      Text(
                        'VIDEO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Delete button
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                iconSize: 20,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageDetailSheet extends StatelessWidget {
  final StorageItem item;

  const _ImageDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    Image.network(
                      item.downloadUrl,
                      fit: BoxFit.contain,
                    ),
                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ClassInfo {
  final String name;
  final int photoCount;
  final int videoCount;

  ClassInfo({
    required this.name,
    required this.photoCount,
    required this.videoCount,
  });

  int get totalCount => photoCount + videoCount;
}
