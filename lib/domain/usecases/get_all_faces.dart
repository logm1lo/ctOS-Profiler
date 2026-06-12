import 'dart:developer' as developer;
import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

class GetAllFaces {
  static const String TAG = "GetAllFaces";
  final FaceRepository repository;

  GetAllFaces(this.repository);

  Future<List<FaceEntity>> execute() async {
    developer.log('[execute] → Entry', name: TAG);
    try {
      final result = await repository.getAllFaces();
      developer.log('[execute] → Exit: count=${result.length}', name: TAG);
      return result;
    } catch (e) {
      developer.log('[execute] → Error: $e', name: TAG, error: e);
      return [];
    }
  }
}
