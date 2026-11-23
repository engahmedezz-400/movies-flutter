import '../../../movies.dart';

abstract interface class FavoritesRepository {
  Stream<List<Movie>> watch();
  Future<void> setSaved(Movie movie, bool saved);
}
