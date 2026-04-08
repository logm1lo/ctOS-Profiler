import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import '../../core/providers/settings_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/entities/face_entity.dart';
import 'camera_controller_provider.dart';
import 'widgets/scanline_painter.dart';
import 'widgets/glitch_painter.dart';

class TargetProfilingScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final fdt.Face face;
  final List<double> embedding;
  final FaceEntity? existingFace;

  const TargetProfilingScreen({
    super.key,
    required this.imageFile,
    required this.face,
    required this.embedding,
    this.existingFace,
  });

  @override
  ConsumerState<TargetProfilingScreen> createState() => _TargetProfilingScreenState();
}

class _TargetProfilingScreenState extends ConsumerState<TargetProfilingScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _occupationController;
  late TextEditingController _ageController;
  late TextEditingController _birthDateController;
  late TextEditingController _heightController;
  late TextEditingController _inchesController; // Added for imperial
  late TextEditingController _weightController;

  late String _incomeLevel;
  late int _riskScore;
  late List<String> _selectedTraits;
  late AnimationController _scanlineController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: widget.existingFace?.name ?? '');
    _occupationController = TextEditingController(text: widget.existingFace?.occupation ?? '');
    _ageController = TextEditingController(text: widget.existingFace?.age?.toString() ?? '25');
    _birthDateController = TextEditingController(text: widget.existingFace?.birthDate ?? '');

    // Initialize unit-aware controllers
    if (settings.measurementUnit == MeasurementUnit.metric) {
      _heightController = TextEditingController(text: widget.existingFace?.height?.toString() ?? '');
      _inchesController = TextEditingController();
      _weightController = TextEditingController(text: widget.existingFace?.weight?.toString() ?? '');
    } else {
      if (widget.existingFace?.height != null) {
        final totalInches = widget.existingFace!.height! / 2.54;
        _heightController = TextEditingController(text: (totalInches / 12).floor().toString());
        _inchesController = TextEditingController(text: (totalInches % 12).round().toString());
      } else {
        _heightController = TextEditingController();
        _inchesController = TextEditingController();
      }

      if (widget.existingFace?.weight != null) {
        final lbs = widget.existingFace!.weight! * 2.20462;
        _weightController = TextEditingController(text: lbs.toStringAsFixed(1));
      } else {
        _weightController = TextEditingController();
      }
    }

    _incomeLevel = widget.existingFace?.incomeLevel ?? 'MIDDLE';
    _riskScore = widget.existingFace?.riskScore ?? 15;
    _selectedTraits = List.from(widget.existingFace?.personalityTraits ?? []);

    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _ageController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    _scanlineController.dispose();
    super.dispose();
  }

  final List<String> _incomeLevels = ['LOW', 'MIDDLE', 'HIGH', 'ELITE'];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);
    final textColor = AppColors.getText(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildBackground(backgroundColor),
          AnimatedBuilder(
            animation: _scanlineController,
            builder: (context, child) => CustomPaint(
              size: Size.infinite,
              painter: GlitchPainter(progress: _scanlineController.value),
            ),
          ),
          AnimatedBuilder(
            animation: _scanlineController,
            builder: (context, child) => CustomPaint(
              size: Size.infinite,
              painter: ScanlinePainter(
                progress: _scanlineController.value,
                color: AppColors.getScanLine(theme),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, accentColor),
                  _buildImagePreview(accentColor),
                  const SizedBox(height: 20),
                  _buildSectionTitle('IDENTIFICATION', theme, accentColor),
                  _buildTextField('NAME', _nameController, theme, accentColor, textColor),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('AGE', _ageController, theme, accentColor, textColor, keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDatePickerField('BIRTH DATE', _birthDateController, theme, accentColor, textColor)),
                    ],
                  ),
                  _buildBiometricsInput(settings, theme, accentColor, textColor),
                  const SizedBox(height: 20),
                  _buildSectionTitle('SOCIO-ECONOMIC STATUS', theme, accentColor),
                  _buildTextField('OCCUPATION', _occupationController, theme, accentColor, textColor),
                  _buildDropdown('INCOME LEVEL', _incomeLevel, _incomeLevels, (v) => setState(() => _incomeLevel = v!), theme, accentColor, textColor),
                  const SizedBox(height: 20),
                  _buildSectionTitle('RISK ASSESSMENT', theme, accentColor),
                  _buildRiskSlider(theme, accentColor),
                  const SizedBox(height: 20),
                  _buildSectionTitle('PERSONALITY PROFILE', theme, accentColor),
                  _buildTraitsSection('POSITIVE', _positiveTraits, AppColors.getSecondaryAccent(theme)),
                  const SizedBox(height: 12),
                  _buildTraitsSection('NEGATIVE', _negativeTraits, theme == AppTheme.whiteBlack ? Colors.red : AppColors.amberWarning),
                  const SizedBox(height: 40),
                  _buildSaveButton(theme, accentColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricsInput(AppSettings settings, AppTheme theme, Color accentColor, Color textColor) {
    if (settings.measurementUnit == MeasurementUnit.metric) {
      return Row(
        children: [
          Expanded(child: _buildTextField('HEIGHT (CM)', _heightController, theme, accentColor, textColor, keyboardType: TextInputType.number)),
          const SizedBox(width: 16),
          Expanded(child: _buildTextField('WEIGHT (KG)', _weightController, theme, accentColor, textColor, keyboardType: TextInputType.number)),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField('HEIGHT (FT)', _heightController, theme, accentColor, textColor, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('INCHES', _inchesController, theme, accentColor, textColor, keyboardType: TextInputType.number)),
            ],
          ),
          _buildTextField('WEIGHT (LBS)', _weightController, theme, accentColor, textColor, keyboardType: TextInputType.number),
        ],
      );
    }
  }

  Widget _buildBackground(Color backgroundColor) {
    return Container(color: backgroundColor);
  }

  Widget _buildSectionTitle(String title, AppTheme theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor.withOpacity(0.7), fontSize: 12, letterSpacing: 2),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text('ctOS // TARGET_PROFILER', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor)),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: 60, color: accentColor),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Color accentColor) {
    return Center(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: accentColor, width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(widget.imageFile, fit: BoxFit.cover),
            _buildFaceOverlay(accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceOverlay(Color accentColor) {
    return Center(
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, AppTheme theme, Color accentColor, Color textColor, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey, fontSize: 10)),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor, fontSize: 14, fontFamily: 'monospace'),
            decoration: InputDecoration(
              isDense: true,
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 0.5)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller, AppTheme theme, Color accentColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey, fontSize: 10)),
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: (theme == AppTheme.whiteBlack ? ThemeData.light() : ThemeData.dark()).copyWith(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: accentColor,
                      brightness: theme == AppTheme.whiteBlack ? Brightness.light : Brightness.dark,
                      primary: accentColor,
                      onPrimary: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      surface: theme == AppTheme.whiteBlack ? Colors.white : Colors.black,
                      onSurface: textColor,
                    ),
                    dialogBackgroundColor: theme == AppTheme.whiteBlack ? Colors.white : Colors.black,
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() {
                  controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                });
              }
            },
            child: TextField(
              controller: controller,
              enabled: false,
              style: TextStyle(color: textColor, fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                isDense: true,
                disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor, width: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSlider(AppTheme theme, Color accentColor) {
    final highRiskColor = Colors.red;
    final isHighRisk = _riskScore > 70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('THREAT LEVEL', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey, fontSize: 10)),
            Text('${_riskScore}%', style: TextStyle(
              color: isHighRisk ? highRiskColor : accentColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace'
            )),
          ],
        ),
        Slider(
          value: _riskScore.toDouble(),
          min: 0,
          max: 100,
          onChanged: (v) => setState(() => _riskScore = v.toInt()),
          activeColor: isHighRisk ? highRiskColor : accentColor,
          inactiveColor: Colors.grey.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildTraitsSection(String title, List<String> traits, Color activeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: activeColor.withOpacity(0.5), fontSize: 10, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: traits.map((trait) {
            final isSelected = _selectedTraits.contains(trait);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTraits.remove(trait);
                  } else {
                    _selectedTraits.add(trait);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(color: isSelected ? activeColor : Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  trait.toUpperCase(),
                  style: TextStyle(color: isSelected ? activeColor : Colors.grey, fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontFamily: 'monospace'),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, AppTheme theme, Color accentColor, Color textColor) {
    final dialogBg = AppColors.getBackground(theme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey, fontSize: 10)),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: dialogBg,
            style: TextStyle(color: textColor, fontSize: 14, fontFamily: 'monospace'),
            underline: Container(height: 0.5, color: accentColor),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppTheme theme, Color accentColor) {
    return GestureDetector(
      onTap: () => _save(context),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: accentColor,
          boxShadow: [
            if (theme == AppTheme.neonBlack)
              BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 10)
          ],
        ),
        child: Center(
          child: Text('FINALIZE PROFILE', style: TextStyle(
            color: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'monospace'
          )),
        ),
      ),
    );
  }

  void _save(BuildContext context) async {
    final name = _nameController.text;
    if (name.isEmpty) return;

    final settings = ref.read(settingsProvider);
    double? height;
    double? weight;

    if (settings.measurementUnit == MeasurementUnit.metric) {
      height = double.tryParse(_heightController.text);
      weight = double.tryParse(_weightController.text);
    } else {
      // Imperial to Metric
      final ft = double.tryParse(_heightController.text) ?? 0;
      final inches = double.tryParse(_inchesController.text) ?? 0;
      height = (ft * 12 + inches) * 2.54;

      final lbs = double.tryParse(_weightController.text) ?? 0;
      weight = lbs / 2.20462;
    }

    final newFace = FaceEntity(
      id: widget.existingFace?.id,
      name: name,
      embedding: widget.embedding,
      modelUsed: widget.existingFace?.modelUsed ?? ref.read(cameraProvider).modelType.name,
      photoPath: widget.imageFile.path,
      timestamp: widget.existingFace?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      age: int.tryParse(_ageController.text),
      occupation: _occupationController.text,
      incomeLevel: _incomeLevel,
      riskScore: _riskScore,
      personalityTraits: _selectedTraits,
      birthDate: _birthDateController.text,
      height: height,
      weight: weight,
    );

    await ref.read(cameraProvider.notifier).saveFace(newFace);
    if (context.mounted) Navigator.pop(context);
  }

  static const List<String> _positiveTraits = [
    'Ambitious', 'Analytical', 'Charismatic', 'Confident', 'Creative',
    'Disciplined', 'Empathetic', 'Focused', 'Honest', 'Inquisitive',
    'Loyal', 'Optimistic', 'Persistent', 'Rational', 'Resourceful'
  ];

  static const List<String> _negativeTraits = [
    'Abrasive', 'Arrogant', 'Cynical', 'Deceptive', 'Impulsive',
    'Irresponsible', 'Manipulative', 'Narcissistic', 'Obsessive', 'Paranoid',
    'Reckless', 'Secretive', 'Stubborn', 'Unpredictable', 'Vindictive'
  ];
}
