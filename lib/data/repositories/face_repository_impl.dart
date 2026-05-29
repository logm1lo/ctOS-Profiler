import 'dart:developer' as developer;
import '../../core/utils/similarity.dart';
import '../../domain/entities/face_entity.dart';
import '../../domain/repositories/face_repository.dart';
import '../datasources/face_local_datasource.dart';
import '../models/face_record.dart';

class FaceRepositoryImpl implements FaceRepository {
  final FaceLocalDataSource localDataSource;
  List<FaceEntity>? _cache;

  FaceRepositoryImpl(this.localDataSource);

  @override
  Future<void> registerFace(FaceEntity face) async {
    await localDataSource.insertFace(FaceRecord.fromEntity(face));
    _cache = null; // Invalidate cache
  }

  @override
  Future<List<FaceEntity>> getAllFaces() async {
    if (_cache != null) return _cache!;
    final records = await localDataSource.getAllFaces();
    _cache = records.map((e) => e as FaceEntity).toList();
    return _cache!;
  }

  @override
  Future<FaceEntity?> matchFace(List<double> embedding, String modelUsed) async {
    final faces = await getAllFaces();
    final filteredFaces = faces.where((f) => f.modelUsed == modelUsed).toList();

    FaceEntity? bestMatch;
    double maxSimilarity = -1.0;
    const double threshold = 0.65; // Slightly higher threshold for accuracy

    developer.log('Matching face... total records: ${filteredFaces.length}');
    for (var face in filteredFaces) {
      // Compare against ALL embeddings for this person
      double personMaxSimilarity = -1.0;
      for (var storedEmbedding in face.embeddings) {
        double similarity = SimilarityUtils.cosineSimilarity(embedding, storedEmbedding);
        if (similarity > personMaxSimilarity) {
          personMaxSimilarity = similarity;
        }
      }

      developer.log('Comparing with ${face.name}: best similarity = $personMaxSimilarity');
      if (personMaxSimilarity > maxSimilarity) {
        maxSimilarity = personMaxSimilarity;
        bestMatch = face;
      }
    }

    if (maxSimilarity >= threshold) {
      developer.log('Match found! Name: ${bestMatch?.name}, Similarity: $maxSimilarity');
      return bestMatch;
    }
    developer.log('No match found. Best similarity: $maxSimilarity (threshold: $threshold)');
    return null;
  }

  @override
  Future<void> addEmbeddingToFace(int faceId, List<double> newEmbedding) async {
    final faces = await getAllFaces();
    final index = faces.indexWhere((f) => f.id == faceId);
    if (index != -1) {
      final face = faces[index];

      // Check if we already have this embedding (roughly) to avoid duplicates
      bool alreadyExists = false;
      for (var existing in face.embeddings) {
        if (SimilarityUtils.cosineSimilarity(newEmbedding, existing) > 0.99) {
          alreadyExists = true;
          break;
        }
      }

      if (!alreadyExists) {
        final updatedEmbeddings = List<List<double>>.from(face.embeddings)..add(newEmbedding);
        final updatedFace = FaceEntity(
          id: face.id,
          name: face.name,
          embeddings: updatedEmbeddings,
          modelUsed: face.modelUsed,
          photoPath: face.photoPath,
          photoBytes: face.photoBytes,
          timestamp: face.timestamp,
          age: face.age,
          occupation: face.occupation,
          incomeLevel: face.incomeLevel,
          riskScore: face.riskScore,
          personalityTraits: face.personalityTraits,
          birthDate: face.birthDate,
          height: face.height,
          weight: face.weight,
        );
        await updateFace(updatedFace);
      }
    }
  }

  @override
  Future<void> deleteFace(int id) async {
    await localDataSource.deleteFace(id);
    _cache = null; // Invalidate cache
  }

  @override
  Future<void> updateFace(FaceEntity face) async {
    await localDataSource.updateFace(FaceRecord.fromEntity(face));
    _cache = null; // Invalidate cache
  }
}
