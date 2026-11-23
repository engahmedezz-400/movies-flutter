import 'movie.dart';

abstract interface class MovieRepository {
  bool get preview;
  Future<List<Movie>> search(String term);
  Future<List<Movie>> homeMovies({required bool action});
  Future<List<Movie>> listMovies(Map<String, String> query);
  Future<List<Movie>> similar(int id);
  Future<Movie> details(int id);
}
