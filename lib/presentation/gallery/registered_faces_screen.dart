import 'dart:io';
import 'dart:developer' as developer;
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
  static const String TAG = "RegisteredFacesScreen";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // developer.log('[build] → Entry', name: TAG);
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
            onPressed: () {
              developer.log('[Interaction] → Opening DB operations menu', name: TAG);
              _showExportImportDialog(context, theme, accentColor, backgroundColor, textColor);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: facesAsyncValue.when(
              data: (faces) {
                if (faces.isEmpty) {
                  return Center(child: Text('NO DATA FOUND', style: AppTextStyles.warning(theme)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: faces.length,
                  itemBuilder: (context, index) {
                    final face = faces[index];
                    return GestureDetector(
                      onTap: () {
                        developer.log('[Navigation] → Inspecting profile: ${face.name}', name: TAG);
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
                              child: _buildFaceImage(face, accentColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          face.name.toUpperCase(),
                                          style: AppTextStyles.body(theme).copyWith(color: accentColor, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (face.isPoi) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.warning, color: Colors.redAccent, size: 14),
                                        const SizedBox(width: 4),
                                        const Text('POI', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('MODEL: ${face.modelUsed.toUpperCase()}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor.withValues(alpha: 0.7))),
                                  Text('DATE: ${DateTime.fromMillisecondsSinceEpoch(face.timestamp).toString().split('.')[0]}', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor.withValues(alpha: 0.7))),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.amberWarning),
                              onPressed: () async {
                                developer.log('[Interaction] → Deletion requested for ID=${face.id}', name: TAG);
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
                );
              },
              loading: () => Center(child: CircularProgressIndicator(color: accentColor)),
              error: (err, stack) {
                developer.log('[build] → Error displaying records: $err', name: TAG, error: err);
                return Center(child: Text('ERROR: $err', style: AppTextStyles.warning(theme)));
              },
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
                    developer.log('[Interaction] → Search query cleared', name: TAG);
                    _searchController.clear();
                    ref.read(facesProvider.notifier).setSearchQuery('');
                  },
                ),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor.withValues(alpha: 0.5))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
              ),
              onChanged: (value) {
                developer.log('[Interaction] → Search query updated: $value', name: TAG);
                ref.read(facesProvider.notifier).setSearchQuery(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceImage(face, Color accentColor) {
    if (face.photoPath.isNotEmpty && File(face.photoPath).existsSync()) {
      return Image.file(File(face.photoPath), fit: BoxFit.cover);
    } else if (face.photoBytes != null && face.photoBytes!.isNotEmpty) {
      return Image.memory(face.photoBytes!, fit: BoxFit.cover);
    } else {
      return Icon(Icons.person, color: accentColor, size: 40);
    }
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
                developer.log('[Interaction] → Database export sequence initiated', name: TAG);
                try {
                  final ds = FaceLocalDataSource();
                  final backupPath = await ds.exportDatabase();
                  final backupFile = File(backupPath);
                  final bytes = await backupFile.readAsBytes();

                  final fileName = 'ctos_faces_backup_${DateTime.now().millisecondsSinceEpoch}.db';
                  final result = await FilePicker.platform.saveFile(
                    dialogTitle: 'Select where to save the database backup',
                    fileName: fileName,
                    bytes: bytes,
                  );

                  if (await backupFile.exists()) {
                    await backupFile.delete();
                  }

                  if (result != null) {
                    developer.log('[Interaction] → Export successful: $result', name: TAG);
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
                  } else {
                    developer.log('[Interaction] → Export canceled by user', name: TAG);
                  }
                } catch (e) {
                  developer.log('[Interaction] → Error: Export failed: $e', name: TAG, error: e);
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
                developer.log('[Interaction] → Database import sequence initiated', name: TAG);
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.path != null) {
                  final ds = FaceLocalDataSource();
                  developer.log('[Interaction] → Importing from: ${result.files.single.path}', name: TAG);
                  await ds.importDatabase(result.files.single.path!);
                  ref.read(facesProvider.notifier).refresh();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Database imported successfully')),
                    );
                  }
                } else {
                  developer.log('[Interaction] → Import canceled by user', name: TAG);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
