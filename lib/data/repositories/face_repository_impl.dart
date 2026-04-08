import '../../core/utils/similarity.dart';
import '../../domain/entities/face_entity.dart';
import '../../domain/repositories/face_repository.dart';
import '../datasources/face_local_datasource.dart';
import '../models/face_record.dart';

class FaceRepositoryImpl implements FaceRepository {
  final FaceLocalDataSource localDataSource;

  FaceRepositoryImpl(this.localDataSource);

  @override
  Future<void> registerFace(FaceEntity face) async {
    await localDataSource.insertFace(FaceRecord.fromEntity(face));
  }

  @override
  Future<List<FaceEntity>> getAllFaces() async {
    final records = await localDataSource.getAllFaces();
    return records.map((e) => e as FaceEntity).toList();
  }

  @override
  Future<FaceEntity?> matchFace(List<double> embedding, String modelUsed) async {
    final faces = await localDataSource.getAllFaces();
    final filteredFaces = faces.where((f) => f.modelUsed == modelUsed).toList();

    FaceEntity? bestMatch;
    double maxSimilarity = -1.0;
    const double threshold = 0.6;

    print('Matching face... total records: ${filteredFaces.length}');
    for (var face in filteredFaces) {
      double similarity = SimilarityUtils.cosineSimilarity(embedding, face.embedding);
      print('Comparing with ${face.name}: similarity = $similarity');
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
        bestMatch = face;
      }
    }

    if (maxSimilarity >= threshold) {
      print('Match found! Name: ${bestMatch?.name}, Similarity: $maxSimilarity');
      return bestMatch;
    }
    print('No match found. Best similarity: $maxSimilarity (threshold: $threshold)');
    return null;

  }

  @override
  Future<void> deleteFace(int id) async {
    await localDataSource.deleteFace(id);
  }

  @override
  Future<void> updateFace(FaceEntity face) async {
    await localDataSource.updateFace(FaceRecord.fromEntity(face));
  }
}
