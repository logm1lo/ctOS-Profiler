import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

class RegisterFace {
  final FaceRepository repository;

  RegisterFace(this.repository);

  Future<void> execute(FaceEntity face) async {
    return await repository.registerFace(face);
  }
}
