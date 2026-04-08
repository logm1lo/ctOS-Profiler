import '../entities/face_entity.dart';

abstract class FaceRepository {
  Future<void> registerFace(FaceEntity face);
  Future<List<FaceEntity>> getAllFaces();
  Future<FaceEntity?> matchFace(List<double> embedding, String modelUsed);
  Future<void> deleteFace(int id);
  Future<void> updateFace(FaceEntity face);
}
