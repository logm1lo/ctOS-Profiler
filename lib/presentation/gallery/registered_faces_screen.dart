import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../data/datasources/face_local_datasource.dart';
import '../../data/repositories/face_repository_impl.dart';
import 'face_detail_screen.dart';
import 'faces_provider.dart';

class RegisteredFacesScreen extends ConsumerStatefulWidget {
  const RegisteredFacesScreen({super.key});

  @override
  ConsumerState<RegisteredFacesScreen> createState() => _RegisteredFacesScreenState();
}

class _RegisteredFacesScreenState extends ConsumerState<RegisteredFacesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final facesAsyncValue = ref.watch(facesProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);
    final surfaceColor = AppColors.getSurface(theme);
    final textColor = AppColors.getText(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('DATABASE', style: AppTextStyles.title(theme).copyWith(fontSize: 18, color: accentColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.import_export, color: accentColor),
            tooltip: 'EXPORT/IMPORT',
            onPressed: () => _showExportImportDialog(context, theme, accentColor, backgroundColor, textColor),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: facesAsyncValue.when(
              data: (faces) => faces.isEmpty
                  ? Center(child: Text('NO DATA FOUND', style: AppTextStyles.warning(theme)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: faces.length,
                      itemBuilder: (context, index) {
                        final face = faces[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FaceDetailScreen(face: face),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                              color: surfaceColor,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: accentColor),
                                  ),
                                  child: face.photoPath.isNotEmpty
                                      ? Image.file(File(face.photoPath), fit: BoxFit.cover)
                                      : Icon(Icons.person, color: accentColor, size: 40),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(face.name.toUpperCase(), style: AppTextStyles.body(theme).copyWith(color: accentColor, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('MODEL: ${face.modelUsed.toUpperCase()}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor.withValues(alpha: 0.7))),
                                      Text('DATE: ${DateTime.fromMillisecondsSinceEpoch(face.timestamp).toString().split('.')[0]}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor.withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.amberWarning),
                                  onPressed: () async {
                                    final dataSource = FaceLocalDataSource();
                                    final repository = FaceRepositoryImpl(dataSource);
                                    if (face.id != null) {
                                      await repository.deleteFace(face.id!);
                                      ref.read(facesProvider.notifier).refresh();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => Center(child: CircularProgressIndicator(color: accentColor)),
              error: (err, stack) => Center(child: Text('ERROR: $err', style: AppTextStyles.warning(theme))),
            ),
          ),

          // Bottom Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(top: BorderSide(color: accentColor, width: 2)),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'SEARCH_DATABASE...',
                hintStyle: TextStyle(color: accentColor.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.search, color: accentColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: accentColor),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(facesProvider.notifier).setSearchQuery('');
                  },
                ),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor.withValues(alpha: 0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
              ),
              onChanged: (value) => ref.read(facesProvider.notifier).setSearchQuery(value),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportImportDialog(BuildContext context, AppTheme theme, Color accentColor, Color backgroundColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(side: BorderSide(color: accentColor)),
        title: Text('DB_OPERATIONS', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.upload, color: accentColor),
              title: Text('EXPORT DATABASE', style: TextStyle(color: textColor, fontFamily: 'monospace')),
              onTap: () async {
                try {
                  final ds = FaceLocalDataSource();
                  // Use the robust export method which creates a consistent backup using VACUUM INTO.
                  // This ensures that even data in the WAL file is included.
                  final backupPath = await ds.exportDatabase();
                  final backupFile = File(backupPath);
                  final bytes = await backupFile.readAsBytes();

                  final fileName = 'ctos_faces_backup_${DateTime.now().millisecondsSinceEpoch}.db';
                  // Use FilePicker to save to a specific file, which handles permissions better
                  final result = await FilePicker.platform.saveFile(
                    dialogTitle: 'Select where to save the database backup',
                    fileName: fileName,
                    bytes: bytes,
                  );

                  // Cleanup the temporary internal backup file
                  if (await backupFile.exists()) {
                    await backupFile.delete();
                  }

                  if (result != null) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('EXPORTED TO: $result', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.white)),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: accentColor),
              title: Text('IMPORT DATABASE', style: TextStyle(color: textColor, fontFamily: 'monospace')),
              onTap: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.path != null) {
                  final ds = FaceLocalDataSource();
                  await ds.importDatabase(result.files.single.path!);
                  ref.read(facesProvider.notifier).refresh();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Database imported successfully')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

