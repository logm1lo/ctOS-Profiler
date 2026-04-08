import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

class MatchFace {
  final FaceRepository repository;

  MatchFace(this.repository);

  Future<FaceEntity?> execute(List<double> embedding, String modelUsed) async {
    return await repository.matchFace(embedding, modelUsed);
  }
}
