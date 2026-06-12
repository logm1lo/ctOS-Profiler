import 'dart:developer' as developer;
import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

class RegisterFace {
  static const String TAG = "RegisterFace";
  final FaceRepository repository;

  RegisterFace(this.repository);

  Future<void> execute(FaceEntity face) async {
    developer.log('[execute] → Entry: name=${face.name}', name: TAG);
    try {
      await repository.registerFace(face);
      developer.log('[execute] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[execute] → Error: $e', name: TAG, error: e);
      rethrow;
    }
  }
}
