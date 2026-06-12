import 'dart:developer' as developer;
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
  static const String TAG = "FacesNotifier";
  final GetAllFaces _getAllFaces;
  List<FaceEntity> _allFaces = [];
  String _searchQuery = '';

  FacesNotifier(this._getAllFaces) : super(const AsyncValue.loading()) {
    developer.log('ctOS_TRACE: FacesNotifier instance created', name: TAG);
    refresh();
  }

  Future<void> refresh() async {
    developer.log('[refresh] → Entry', name: TAG);
    if (!mounted) {
      developer.log('[refresh] → Exit: Not mounted', name: TAG);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final faces = await _getAllFaces.execute();
      if (!mounted) {
        developer.log('[refresh] → Exit: Not mounted after execute', name: TAG);
        return;
      }
      _allFaces = faces;
      developer.log('[refresh] → Status: Retrieved ${faces.length} faces, applying filters', name: TAG);
      _applyFilter();
      developer.log('[refresh] → Exit: Completed successfully', name: TAG);
    } catch (e, stack) {
      developer.log('[refresh] → Error: $e', name: TAG, error: e, stackTrace: stack);
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  void setSearchQuery(String query) {
    developer.log('[setSearchQuery] → Entry: query=$query', name: TAG);
    _searchQuery = query.toLowerCase();
    _applyFilter();
    developer.log('[setSearchQuery] → Exit: Filter applied', name: TAG);
  }

  void _applyFilter() {
    developer.log('[_applyFilter] → Entry: searchQuery=$_searchQuery', name: TAG);
    if (_searchQuery.isEmpty) {
      developer.log('[_applyFilter] → Status: Query empty, showing all ${_allFaces.length} records', name: TAG);
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
      developer.log('[_applyFilter] → Exit: Filtered to ${filtered.length} matches', name: TAG);
      state = AsyncValue.data(filtered);
    }
  }
}

final faceProvider = FutureProvider.family<FaceEntity?, int>((ref, id) async {
  developer.log('faceProvider(id: $id) → Entry', name: "faceProvider");
  final facesAsync = ref.watch(facesProvider);
  return facesAsync.when(
    data: (faces) {
      try {
        final match = faces.firstWhere((f) => f.id == id);
        developer.log('faceProvider(id: $id) → Exit: Found target ${match.name}', name: "faceProvider");
        return match;
      } catch (e) {
        developer.log('faceProvider(id: $id) → Error: Target not found in local cache', name: "faceProvider");
        throw 'Face not found';
      }
    },
    loading: () => null,
    error: (e, _) {
      developer.log('faceProvider(id: $id) → Error: $e', name: "faceProvider");
      return null;
    },
  );
});
