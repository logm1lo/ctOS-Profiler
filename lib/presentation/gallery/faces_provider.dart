import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/face_entity.dart';
import '../../data/datasources/face_local_datasource.dart';
import '../../data/repositories/face_repository_impl.dart';
import '../../domain/usecases/get_all_faces.dart';

final facesProvider = StateNotifierProvider<FacesNotifier, AsyncValue<List<FaceEntity>>>((ref) {
  final dataSource = FaceLocalDataSource();
  final repository = FaceRepositoryImpl(dataSource);
  return FacesNotifier(GetAllFaces(repository));
});

class FacesNotifier extends StateNotifier<AsyncValue<List<FaceEntity>>> {
  final GetAllFaces _getAllFaces;
  List<FaceEntity> _allFaces = [];
  String _searchQuery = '';

  FacesNotifier(this._getAllFaces) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      _allFaces = await _getAllFaces.execute();
      _applyFilter();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      state = AsyncValue.data(_allFaces);
    } else {
      final filtered = _allFaces.where((face) {
        final name = face.name.toLowerCase();
        final occupation = face.occupation?.toLowerCase() ?? '';
        final age = face.age?.toString() ?? '';
        final risk = face.riskScore?.toString() ?? '';
        final birthDate = face.birthDate?.toLowerCase() ?? '';
        final height = face.height?.toString() ?? '';
        final weight = face.weight?.toString() ?? '';

        return name.contains(_searchQuery) ||
               occupation.contains(_searchQuery) ||
               age.contains(_searchQuery) ||
               risk.contains(_searchQuery) ||
               birthDate.contains(_searchQuery) ||
               height.contains(_searchQuery) ||
               weight.contains(_searchQuery);
      }).toList();
      state = AsyncValue.data(filtered);
    }
  }
}

final faceProvider = FutureProvider.family<FaceEntity?, int>((ref, id) async {
  final facesAsync = ref.watch(facesProvider);
  return facesAsync.when(
    data: (faces) => faces.firstWhere((f) => f.id == id, orElse: () => throw 'Face not found'),
    loading: () => null,
    error: (_, __) => null,
  );
});
