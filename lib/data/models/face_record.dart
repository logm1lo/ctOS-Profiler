import 'dart:convert';
import '../../domain/entities/face_entity.dart';

class FaceRecord extends FaceEntity {
  FaceRecord({
    super.id,
    required super.name,
    required super.embedding,
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
      'embedding': jsonEncode(embedding),
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
    return FaceRecord(
      id: map['id'],
      name: map['name'],
      embedding: map['embedding'] is String
          ? (jsonDecode(map['embedding']) as List).map((e) => (e as num).toDouble()).toList()
          : (map['embedding'] as List).cast<double>(),
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
      embedding: entity.embedding,
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
