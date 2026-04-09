import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../domain/entities/face_entity.dart';
import '../camera/target_profiling_screen.dart';
import 'faces_provider.dart';

class FaceDetailScreen extends ConsumerWidget {
  final FaceEntity face;

  const FaceDetailScreen({super.key, required this.face});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faceAsync = ref.watch(faceProvider(face.id!));
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);
    final surfaceColor = AppColors.getSurface(theme);
    final textColor = AppColors.getText(theme);

    return faceAsync.when(
      data: (updatedFace) {
        final currentFace = updatedFace ?? face;
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('PROFILE_DATA', style: AppTextStyles.title(theme).copyWith(fontSize: 18, color: accentColor)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: accentColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              _buildBackground(),
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, currentFace, theme, accentColor),
                    const SizedBox(height: 32),
                    _buildInfoSection('DEMOGRAPHICS', [
                      _infoRow('BIRTH DATE', currentFace.birthDate ?? "UNKNOWN", theme, textColor),
                      _infoRow('AGE', '${currentFace.age ?? "UNKNOWN"}', theme, textColor),
                      _infoRow('OCCUPATION', currentFace.occupation?.toUpperCase() ?? "UNKNOWN", theme, textColor),
                      _infoRow('INCOME', currentFace.incomeLevel ?? "UNKNOWN", theme, textColor),
                    ], theme, accentColor, surfaceColor),
                    const SizedBox(height: 24),
                    _buildInfoSection('BIOMETRICS', [
                      _infoRow('HEIGHT', _formatHeight(currentFace.height, settings.measurementUnit), theme, textColor),
                      _infoRow('WEIGHT', _formatWeight(currentFace.weight, settings.measurementUnit), theme, textColor),
                    ], theme, accentColor, surfaceColor),
                    const SizedBox(height: 24),
                    _buildInfoSection('ctOS ANALYSIS', [
                      _infoRow('RISK SCORE', '${currentFace.riskScore ?? 0}%', theme, textColor, color: _getRiskColor(currentFace.riskScore ?? 0)),
                      _infoRow('THREAT LEVEL', _getThreatLevel(currentFace.riskScore ?? 0), theme, textColor, color: _getRiskColor(currentFace.riskScore ?? 0)),
                    ], theme, accentColor, surfaceColor),
                    const SizedBox(height: 24),
                    _buildTraitsSection(currentFace, theme, accentColor),
                    const SizedBox(height: 24),
                    _buildInfoSection('SYSTEM DATA', [
                      _infoRow('MODEL', currentFace.modelUsed.toUpperCase(), theme, textColor),
                      _infoRow('DATE', DateTime.fromMillisecondsSinceEpoch(currentFace.timestamp).toString().split('.')[0], theme, textColor),
                    ], theme, accentColor, surfaceColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(backgroundColor: backgroundColor, body: Center(child: CircularProgressIndicator(color: accentColor))),
      error: (e, s) => Scaffold(backgroundColor: backgroundColor, body: Center(child: Text('ERROR: $e', style: AppTextStyles.warning(theme)))),
    );
  }

  Widget _buildBackground() {
    return Container();
  }

  Widget _buildProfileHeader(BuildContext context, FaceEntity currentFace, AppTheme theme, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: accentColor, width: 2),
            boxShadow: [
              if (theme == AppTheme.neonBlack)
                BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 10)
            ],
          ),
          child: _buildFaceImage(currentFace, accentColor),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentFace.name.toUpperCase(),
                      style: AppTextStyles.title(theme).copyWith(fontSize: 22, color: accentColor),
                    ),
                  ),
                    IconButton(
                    icon: Icon(Icons.edit, color: accentColor, size: 20),
                    onPressed: () {
                      const size = Size(100, 100);
                      final detection = fdt.Detection(
                        boundingBox: const fdt.RectF(0, 0, 1, 1),
                        score: 1.0,
                        keypointsXY: const [0,0,0,0,0,0,0,0,0,0,0,0], // 6 landmarks * 2 (x,y)
                        imageSize: size,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (innerContext) => TargetProfilingScreen(
                            imageFile: File(currentFace.photoPath),
                            face: fdt.Face(
                              detection: detection,
                              mesh: null,
                              irises: [],
                              originalSize: size,
                            ),
                            embedding: currentFace.embedding,
                            existingFace: currentFace,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'ID: ${currentFace.id ?? "NEW_TARGET"}',
                  style: AppTextStyles.hudStatus(theme).copyWith(fontSize: 10, color: accentColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, AppTheme theme, Color accentColor, Color surfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: accentColor),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.5),
            border: Border(left: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, AppTheme theme, Color textColor, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey, fontSize: 10)),
          Text(value, style: AppTextStyles.body(theme).copyWith(fontSize: 14, color: color ?? textColor)),
        ],
      ),
    );
  }

  Widget _buildTraitsSection(FaceEntity currentFace, AppTheme theme, Color accentColor) {
    if (currentFace.personalityTraits == null || currentFace.personalityTraits!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: accentColor),
            const SizedBox(width: 8),
            Text('PERSONALITY TRAITS', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: currentFace.personalityTraits!.map((trait) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                color: accentColor.withValues(alpha: 0.05),
              ),
              child: Text(
                trait.toUpperCase(),
                style: AppTextStyles.hudStatus(theme).copyWith(fontSize: 10, color: accentColor),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getRiskColor(int score) {
    if (score < 30) return Colors.greenAccent;
    if (score < 70) return Colors.amberAccent;
    return Colors.redAccent;
  }

  String _getThreatLevel(int score) {
    if (score < 30) return 'LOW';
    if (score < 60) return 'ELEVATED';
    if (score < 85) return 'HIGH';
    return 'CRITICAL';
  }

  String _formatHeight(double? heightCm, MeasurementUnit unit) {
    if (heightCm == null) return "UNKNOWN";
    if (unit == MeasurementUnit.metric) {
      return "${heightCm.toStringAsFixed(1)} CM";
    } else {
      final totalInches = heightCm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return "$feet'$inches\"";
    }
  }

  String _formatWeight(double? weightKg, MeasurementUnit unit) {
    if (weightKg == null) return "UNKNOWN";
    if (unit == MeasurementUnit.metric) {
      return "${weightKg.toStringAsFixed(1)} KG";
    } else {
      final lbs = weightKg * 2.20462;
      return "${lbs.toStringAsFixed(1)} LBS";
    }
  }

  Widget _buildFaceImage(FaceEntity face, Color accentColor) {
    if (face.photoPath.isNotEmpty && File(face.photoPath).existsSync()) {
      return Image.file(File(face.photoPath), fit: BoxFit.cover);
    } else if (face.photoBytes != null && face.photoBytes!.isNotEmpty) {
      return Image.memory(face.photoBytes!, fit: BoxFit.cover);
    } else {
      return Icon(Icons.person, color: accentColor, size: 60);
    }
  }
}
