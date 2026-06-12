import 'dart:convert';
import 'dart:developer' as developer;
import '../../domain/entities/face_entity.dart';

class FaceRecord extends FaceEntity {
  static const String TAG = "FaceRecord";

  FaceRecord({
    super.id,
    required super.name,
    required super.embeddings,
    required super.modelUsed,
    required super.photoPath,
    super.photoBytes,
    required super.timestamp,
    super.age,
    super.occupation,
    super.incomeLevel,
    super.riskScore,
    super.personalityTraits,
    super.birthDate,
    super.height,
    super.weight,
    super.hobby,
    super.secret,
    super.recentHistory,
    super.socialLinks,
    super.aliases,
    super.digitalFootprintSummary,
    super.isPoi,
  });

  @override
  Map<String, dynamic> toMap() {
    // developer.log('[toMap] → Entry: name=$name', name: TAG);
    return {
      'id': id,
      'name': name,
      'embedding': jsonEncode(embeddings),
      'model_used': modelUsed,
      'photo_path': photoPath,
      'photo_bytes': photoBytes,
      'timestamp': timestamp,
      'age': age,
      'occupation': occupation,
      'income_level': incomeLevel,
      'risk_score': riskScore,
      'personality_traits': personalityTraits != null ? jsonEncode(personalityTraits) : null,
      'birth_date': birthDate,
      'height': height,
      'weight': weight,
      'hobby': hobby,
      'secret': secret,
      'recent_history': recentHistory != null ? jsonEncode(recentHistory) : null,
      'social_links': socialLinks != null ? jsonEncode(socialLinks) : null,
      'aliases': aliases != null ? jsonEncode(aliases) : null,
      'digital_footprint_summary': digitalFootprintSummary,
      'is_poi': isPoi ? 1 : 0,
    };
  }

  factory FaceRecord.fromMap(Map<String, dynamic> map) {
    // developer.log('[fromMap] → Entry: id=${map['id']}', name: TAG);
    List<List<double>> embeddingsList = [];
    if (map['embedding'] is String) {
      try {
        final decoded = jsonDecode(map['embedding']);
        if (decoded is List) {
          if (decoded.isNotEmpty && decoded.first is List) {
            embeddingsList = decoded.map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList();
          } else {
            embeddingsList = [(decoded).map((e) => (e as num).toDouble()).toList()];
          }
        }
      } catch (e) {
        developer.log('[fromMap] → Error decoding embedding: $e', name: TAG);
      }
    }

    return FaceRecord(
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
      personalityTraits: map['personality_traits'] != null
          ? (jsonDecode(map['personality_traits']) as List).map((e) => e as String).toList()
          : null,
      birthDate: map['birth_date'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      hobby: map['hobby'],
      secret: map['secret'],
      recentHistory: map['recent_history'] != null
          ? (jsonDecode(map['recent_history']) as List).map((e) => e as String).toList()
          : null,
      socialLinks: map['social_links'] != null
          ? (jsonDecode(map['social_links']) as List).map((e) => e as String).toList()
          : null,
      aliases: map['aliases'] != null
          ? (jsonDecode(map['aliases']) as List).map((e) => e as String).toList()
          : null,
      digitalFootprintSummary: map['digital_footprint_summary'],
      isPoi: (map['is_poi'] ?? 0) == 1,
    );
  }

  factory FaceRecord.fromEntity(FaceEntity entity) {
    return FaceRecord(
      id: entity.id,
      name: entity.name,
      embeddings: entity.embeddings,
      modelUsed: entity.modelUsed,
      photoPath: entity.photoPath,
      photoBytes: entity.photoBytes,
      timestamp: entity.timestamp,
      age: entity.age,
      occupation: entity.occupation,
      incomeLevel: entity.incomeLevel,
      riskScore: entity.riskScore,
      personalityTraits: entity.personalityTraits,
      birthDate: entity.birthDate,
      height: entity.height,
      weight: entity.weight,
      hobby: entity.hobby,
      secret: entity.secret,
      recentHistory: entity.recentHistory,
      socialLinks: entity.socialLinks,
      aliases: entity.aliases,
      digitalFootprintSummary: entity.digitalFootprintSummary,
      isPoi: entity.isPoi,
    );
  }
}
