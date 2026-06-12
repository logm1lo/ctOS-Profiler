import 'dart:typed_data';

class FaceEntity {
  final int? id;
  final String name;
  final List<List<double>> embeddings;
  final String modelUsed;
  final String photoPath;
  final Uint8List? photoBytes;
  final int timestamp;

  // Watch Dogs style profiling data
  final int? age;
  final String? occupation;
  final String? incomeLevel;
  final int? riskScore; // 0-100
  final List<String>? personalityTraits;
  final String? birthDate;
  final double? height;
  final double? weight;

  // New Flavor Data
  final String? hobby;
  final String? secret;
  final List<String>? recentHistory;

  // OSINT Data
  final List<String>? socialLinks;
  final List<String>? aliases;
  final String? digitalFootprintSummary;
  final Map<String, dynamic>? extraMetadata;
  final bool isPoi;

  FaceEntity({
    this.id,
    required this.name,
    required this.embeddings,
    required this.modelUsed,
    required this.photoPath,
    this.photoBytes,
    required this.timestamp,
    this.age,
    this.occupation,
    this.incomeLevel,
    this.riskScore,
    this.personalityTraits,
    this.birthDate,
    this.height,
    this.weight,
    this.hobby,
    this.secret,
    this.recentHistory,
    this.socialLinks,
    this.aliases,
    this.digitalFootprintSummary,
    this.extraMetadata,
    this.isPoi = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'embeddings': embeddings.map((e) => e.join(',')).join('|'),
      'model_used': modelUsed,
      'photo_path': photoPath,
      'photo_bytes': photoBytes,
      'timestamp': timestamp,
      'age': age,
      'occupation': occupation,
      'income_level': incomeLevel,
      'risk_score': riskScore,
      'personality_traits': personalityTraits?.join(','),
      'birth_date': birthDate,
      'height': height,
      'weight': weight,
      'hobby': hobby,
      'secret': secret,
      'recent_history': recentHistory?.join('|'),
      'social_links': socialLinks?.join('|'),
      'aliases': aliases?.join('|'),
      'digital_footprint_summary': digitalFootprintSummary,
      'is_poi': isPoi ? 1 : 0,
    };
  }

  factory FaceEntity.fromMap(Map<String, dynamic> map) {
    List<List<double>> embeddingsList = [];
    if (map['embeddings'] != null && map['embeddings'] is String) {
      embeddingsList = (map['embeddings'] as String)
          .split('|')
          .where((s) => s.isNotEmpty)
          .map((s) => s.split(',').map((e) => double.parse(e)).toList())
          .toList();
    } else if (map['embedding'] != null) {
      if (map['embedding'] is String) {
        embeddingsList = [(map['embedding'] as String).split(',').map((e) => double.parse(e)).toList()];
      } else if (map['embedding'] is List) {
        embeddingsList = [(map['embedding'] as List).cast<double>()];
      }
    }

    return FaceEntity(
      id: map['id'],
      name: map['name'],
      embeddings: embeddingsList,
      modelUsed: map['model_used'] ?? '',
      photoPath: map['photo_path'] ?? '',
      photoBytes: map['photo_bytes'],
      timestamp: map['timestamp'] ?? 0,
      age: map['age'],
      occupation: map['occupation'],
      incomeLevel: map['income_level'],
      riskScore: map['risk_score'],
      personalityTraits: (map['personality_traits'] as String?)?.split(',').where((s) => s.isNotEmpty).toList(),
      birthDate: map['birth_date'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      hobby: map['hobby'],
      secret: map['secret'],
      recentHistory: (map['recent_history'] as String?)?.split('|').where((s) => s.isNotEmpty).toList(),
      socialLinks: (map['social_links'] as String?)?.split('|').where((s) => s.isNotEmpty).toList(),
      aliases: (map['aliases'] as String?)?.split('|').where((s) => s.isNotEmpty).toList(),
      digitalFootprintSummary: map['digital_footprint_summary'],
      isPoi: (map['is_poi'] ?? 0) == 1,
    );
  }
}
