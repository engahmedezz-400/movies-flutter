import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'movies.dart';

class MovieHistory {
  final String uid;
  MovieHistory(this.uid);
  final prefs = SharedPreferencesAsync();

  String get prefix => 'history.$uid.';
  Future<void> record(Movie movie) {
    return prefs.setString('$prefix${movie.id}', jsonEncode({
      'opened': DateTime.now().microsecondsSinceEpoch,
      'id': movie.id, 'title': movie.title, 'year': movie.year,
      'rating': movie.rating, 'medium_cover_image': movie.poster,
      'description_full': movie.summary,
    }));
  }

  Future<void> clear() async {
    final keys = await prefs.getKeys();
    final historyKeys = keys.where((key) => key.startsWith(prefix)).toSet();
    if (historyKeys.isNotEmpty) {
      await prefs.clear(allowList: historyKeys);
    }
  }

  Future<List<Movie>> movies() async {
    final keys = await prefs.getKeys();
    final rows = <Map<String, dynamic>>[];
    for (final key in keys.where((key) => key.startsWith(prefix))) {
      final value = await prefs.getString(key);
      if (value != null) rows.add(jsonDecode(value) as Map<String, dynamic>);
    }
    rows.sort((a, b) => (b['opened'] as int).compareTo(a['opened'] as int));
    return rows.map(Movie.fromJson).toList();
  }
}
