import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../providers/media_provider.dart';
import '../services/upload_services.dart';
import 'capture_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UploadService _uploadService = UploadService();
  int _storagePhotoCount = 0;
  int _storageVideoCount = 0;
  int _storageDatasetCount = 0;
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    _loadStorageCounts();
  }

  Future<void> _loadStorageCounts() async {
    try {
      final items = await _uploadService.listAllMedia();
      if (mounted) {
        final datasetNames = items
            .map((i) => i.datasetName)
            .where((name) => name != null)
            .toSet();
        setState(() {
          _storagePhotoCount = items.where((i) => i.isImage).length;
          _storageVideoCount = items.where((i) => i.isVideo).length;
          _storageDatasetCount = datasetNames.length;
          _isLoadingStorage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStorage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              _buildHeader(theme, isDark),
              const SizedBox(height: AppSpacing.xl),
              _buildStatsCard(context, theme, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(theme, 'Quick Actions'),
              const SizedBox(height: AppSpacing.md),
              _buildActionGrid(context, theme, isDark),
              const SizedBox(height: AppSpacing.xl),
              _buildInfoCard(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.data_object,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DataCap',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ML Data Collection',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, ThemeData theme, bool isDark) {
    return Consumer<MediaProvider>(
      builder: (ctx, provider, _) {
        return Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                _buildStatItem(
                  theme,
                  isDark,
                  Icons.photo_library_outlined,
                  _isLoadingStorage ? '-' : _storagePhotoCount.toString(),
                  'Photos',
                  AppColors.primary,
                ),
                _buildStatDivider(isDark),
                _buildStatItem(
                  theme,
                  isDark,
                  Icons.video_library_outlined,
                  _isLoadingStorage ? '-' : _storageVideoCount.toString(),
                  'Videos',
                  AppColors.secondary,
                ),
                _buildStatDivider(isDark),
                _buildStatItem(
                  theme,
                  isDark,
                  Icons.folder_outlined,
                  _isLoadingStorage ? '-' : _storageDatasetCount.toString(),
                  'Datasets',
                  AppColors.tertiary,
                ),
                _buildStatDivider(isDark),
                _buildStatItem(
                  theme,
                  isDark,
                  Icons.cloud_upload_outlined,
                  provider.pendingCount.toString(),
                  'Pending',
                  AppColors.info,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariantLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 60,
      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                isDark,
                icon: Icons.photo_camera,
                title: 'Capture Photos',
                subtitle: 'Take or import photos',
                color: AppColors.primary,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CaptureScreen(
                        initialMode: CaptureMode.photo,
                      ),
                    ),
                  );
                  _loadStorageCounts();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                isDark,
                icon: Icons.videocam,
                title: 'Capture Videos',
                subtitle: 'Record or import videos',
                color: AppColors.secondary,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CaptureScreen(
                        initialMode: CaptureMode.video,
                      ),
                    ),
                  );
                  _loadStorageCounts();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                isDark,
                icon: Icons.cloud_done_outlined,
                title: 'View Gallery',
                subtitle: 'Browse uploaded media',
                color: AppColors.tertiary,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GalleryScreen(),
                    ),
                  );
                  _loadStorageCounts();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    return Card(
      color: isDark
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Tip',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use consistent class labels across your dataset for better ML model training results.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariantLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
