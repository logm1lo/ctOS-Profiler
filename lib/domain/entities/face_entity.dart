class FaceEntity {
  final int? id;
  final String name;
  final List<double> embedding;
  final String modelUsed;
  final String photoPath;
  final int timestamp;

  // New Watch Dogs style profiling data
  final int? age;
  final String? occupation;
  final String? incomeLevel;
  final int? riskScore; // 0-100
  final List<String>? personalityTraits;
  final String? birthDate;
  final double? height;
  final double? weight;

  FaceEntity({
    this.id,
    required this.name,
    required this.embedding,
    required this.modelUsed,
    required this.photoPath,
    required this.timestamp,
    this.age,
    this.occupation,
    this.incomeLevel,
    this.riskScore,
    this.personalityTraits,
    this.birthDate,
    this.height,
    this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'embedding': embedding.join(','),
      'model_used': modelUsed,
      'photo_path': photoPath,
      'timestamp': timestamp,
      'age': age,
      'occupation': occupation,
      'income_level': incomeLevel,
      'risk_score': riskScore,
      'personality_traits': personalityTraits?.join(','),
      'birth_date': birthDate,
      'height': height,
      'weight': weight,
    };
  }

  factory FaceEntity.fromMap(Map<String, dynamic> map) {
    return FaceEntity(
      id: map['id'],
      name: map['name'],
      embedding: map['embedding'] is String
        ? (map['embedding'] as String).split(',').map((e) => double.parse(e)).toList()
        : (map['embedding'] as List).cast<double>(),
      modelUsed: map['model_used'] ?? '',
      photoPath: map['photo_path'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      age: map['age'],
      occupation: map['occupation'],
      incomeLevel: map['income_level'],
      riskScore: map['risk_score'],
      personalityTraits: (map['personality_traits'] as String?)?.split(',').where((s) => s.isNotEmpty).toList(),
      birthDate: map['birth_date'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
    );
  }

}
