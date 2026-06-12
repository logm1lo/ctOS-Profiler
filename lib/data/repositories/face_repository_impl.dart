import 'dart:developer' as developer;
import '../../core/utils/similarity.dart';
import '../../domain/entities/face_entity.dart';
import '../../domain/repositories/face_repository.dart';
import '../datasources/face_local_datasource.dart';
import '../models/face_record.dart';

class FaceRepositoryImpl implements FaceRepository {
  static const String TAG = "FaceRepositoryImpl";
  final FaceLocalDataSource localDataSource;
  List<FaceEntity>? _cache;

  FaceRepositoryImpl(this.localDataSource);

  @override
  Future<void> registerFace(FaceEntity face) async {
    developer.log('[registerFace] → Entry: name=${face.name}', name: TAG);
    try {
      await localDataSource.insertFace(FaceRecord.fromEntity(face));
      _cache = null; // Invalidate cache
      developer.log('[registerFace] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[registerFace] → Error: $e', name: TAG, error: e);
      rethrow;
    }
  }

  @override
  Future<List<FaceEntity>> getAllFaces() async {
    developer.log('[getAllFaces] → Entry', name: TAG);
    if (_cache != null) {
      developer.log('[getAllFaces] → Exit: Returning ${_cache!.length} cached entities', name: TAG);
      return _cache!;
    }
    try {
      final records = await localDataSource.getAllFaces();
      _cache = records.map((e) => e as FaceEntity).toList();
      developer.log('[getAllFaces] → Exit: Fetched ${_cache!.length} entities from DB', name: TAG);
      return _cache!;
    } catch (e) {
      developer.log('[getAllFaces] → Error: $e', name: TAG, error: e);
      return [];
    }
  }

  @override
  Future<FaceEntity?> matchFace(List<double> embedding, String modelUsed) async {
    developer.log('[matchFace] → Entry: model=$modelUsed', name: TAG);
    try {
      final faces = await getAllFaces();
      final filteredFaces = faces.where((f) => f.modelUsed == modelUsed).toList();
      developer.log('[matchFace] → Status: Searching through ${filteredFaces.length} targets using $modelUsed', name: TAG);

      FaceEntity? bestMatch;
      double maxSimilarity = -1.0;
      const double threshold = 0.65; // Slightly higher threshold for accuracy

      for (var face in filteredFaces) {
        double personMaxSimilarity = -1.0;
        for (var storedEmbedding in face.embeddings) {
          double similarity = SimilarityUtils.cosineSimilarity(embedding, storedEmbedding);
          if (similarity > personMaxSimilarity) {
            personMaxSimilarity = similarity;
          }
        }

        if (personMaxSimilarity > maxSimilarity) {
          maxSimilarity = personMaxSimilarity;
          bestMatch = face;
        }
      }

      if (maxSimilarity >= threshold) {
        developer.log('[matchFace] → Exit: Match found! Name: ${bestMatch?.name}, Similarity: $maxSimilarity', name: TAG);
        return bestMatch;
      }
      developer.log('[matchFace] → Exit: No match found. Best similarity: $maxSimilarity (threshold: $threshold)', name: TAG);
      return null;
    } catch (e) {
      developer.log('[matchFace] → Error: $e', name: TAG, error: e);
      return null;
    }
  }

  @override
  Future<void> addEmbeddingToFace(int faceId, List<double> newEmbedding) async {
    developer.log('[addEmbeddingToFace] → Entry: faceId=$faceId', name: TAG);
    try {
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
          developer.log('[addEmbeddingToFace] → Status: Adding unique sample to ${face.name}', name: TAG);
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
            hobby: face.hobby,
            secret: face.secret,
            recentHistory: face.recentHistory,
            socialLinks: face.socialLinks,
            aliases: face.aliases,
            digitalFootprintSummary: face.digitalFootprintSummary,
            isPoi: face.isPoi,
          );
          await updateFace(updatedFace);
          developer.log('[addEmbeddingToFace] → Exit: Completed successfully', name: TAG);
        } else {
          developer.log('[addEmbeddingToFace] → Exit: Sample already exists, skipping', name: TAG);
        }
      } else {
        developer.log('[addEmbeddingToFace] → Warning: Target ID $faceId not found', name: TAG);
      }
    } catch (e) {
      developer.log('[addEmbeddingToFace] → Error: $e', name: TAG, error: e);
    }
  }

  @override
  Future<void> deleteFace(int id) async {
    developer.log('[deleteFace] → Entry: id=$id', name: TAG);
    try {
      await localDataSource.deleteFace(id);
      _cache = null; // Invalidate cache
      developer.log('[deleteFace] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[deleteFace] → Error: $e', name: TAG, error: e);
    }
  }

  @override
  Future<void> updateFace(FaceEntity face) async {
    developer.log('[updateFace] → Entry: id=${face.id}, name=${face.name}', name: TAG);
    try {
      await localDataSource.updateFace(FaceRecord.fromEntity(face));
      _cache = null; // Invalidate cache
      developer.log('[updateFace] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[updateFace] → Error: $e', name: TAG, error: e);
    }
  }
}
