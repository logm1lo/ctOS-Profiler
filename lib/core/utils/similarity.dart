import 'dart:developer' as developer;
import 'dart:math';

class SimilarityUtils {
  static const String TAG = "SimilarityUtils";

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      developer.log('[cosineSimilarity] → Error: Dimension mismatch (${a.length} vs ${b.length})', name: TAG);
      return 0.0;
    }
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    final int len = a.length;
    for (int i = 0; i < len; i++) {
      final double va = a[i];
      final double vb = b[i];
      dotProduct += va * vb;
      normA += va * va;
      normB += vb * vb;
    }
    if (normA == 0 || normB == 0) return 0.0;
    final double result = dotProduct / (sqrt(normA) * sqrt(normB));
    // developer.log('[cosineSimilarity] → Exit: result=$result', name: TAG); // Noise reduction
    return result;
  }

  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      developer.log('[euclideanDistance] → Error: Dimension mismatch (${a.length} vs ${b.length})', name: TAG);
      return double.infinity;
    }
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    final double result = sqrt(sum);
    // developer.log('[euclideanDistance] → Exit: result=$result', name: TAG); // Noise reduction
    return result;
  }
}
