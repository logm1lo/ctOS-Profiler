import 'dart:developer' as developer;
import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

class MatchFace {
  static const String TAG = "MatchFace";
  final FaceRepository repository;

  MatchFace(this.repository);

  Future<FaceEntity?> execute(List<double> embedding, String modelUsed) async {
    developer.log('[execute] → Entry: modelUsed=$modelUsed', name: TAG);
    try {
      final result = await repository.matchFace(embedding, modelUsed);
      developer.log('[execute] → Exit: matchFound=${result != null}', name: TAG);
      return result;
    } catch (e) {
      developer.log('[execute] → Error: $e', name: TAG, error: e);
      return null;
    }
  }
}
