import 'dart:math';

class SimilarityUtils {
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
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
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) return double.infinity;
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }
}
