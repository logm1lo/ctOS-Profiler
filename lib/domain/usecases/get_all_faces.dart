import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

class GetAllFaces {
  final FaceRepository repository;

  GetAllFaces(this.repository);

  Future<List<FaceEntity>> execute() async {
    return await repository.getAllFaces();
  }
}
