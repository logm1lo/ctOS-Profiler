import 'dart:convert';
import '../../domain/entities/face_entity.dart';

class FaceRecord extends FaceEntity {
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
  });

  @override
  Map<String, dynamic> toMap() {
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
    };
  }

  factory FaceRecord.fromMap(Map<String, dynamic> map) {
    List<List<double>> embeddingsList = [];
    if (map['embedding'] is String) {
      final decoded = jsonDecode(map['embedding']);
      if (decoded is List) {
        if (decoded.isNotEmpty && decoded.first is List) {
          // New format: List<List<double>>
          embeddingsList = decoded.map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList();
        } else {
          // Old format: List<double>
          embeddingsList = [(decoded).map((e) => (e as num).toDouble()).toList()];
        }
      }
    }

    return FaceRecord(
      id: map['id'],
      name: map['name'],
      embeddings: embeddingsList,
      modelUsed: map['model_used'],
      photoPath: map['photo_path'],
      photoBytes: map['photo_bytes'],
      timestamp: map['timestamp'],
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
    );
  }
}
