import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dart:collection';
import 'package:crypto/crypto.dart';
import '../domain/movie.dart';
import '../domain/movie_repository.dart';
import 'catalog_cache.dart';

const samples = [
  Movie(1, 'Midnight in Cairo', '2024', '', '7.8', 'A young photographer follows an old map across Cairo.'),
  Movie(2, 'The Last Frame', '2023', '', '8.1', 'A projectionist finds a missing reel on the last night of a cinema.')
];

class MovieCatalog implements MovieRepository {
  @override
  final bool preview;
  const MovieCatalog({this.preview = false});

  Future<Map<String, dynamic>> request(String path, Map<String, String> query) async {
    final url = Uri.https('yts.lt', '/api/v2/$path.json', query);
    final cacheKey = sha256.convert(utf8.encode(Uri.https('yts.lt', url.path,
        SplayTreeMap<String, String>.from(query)).toString())).toString();
    late Map<String, dynamic> data;
    try {
      data = await _download(url);
    } catch (error, stack) {
      try {
        final cached = await CatalogCache.read(cacheKey);
        if (cached != null) return cached;
      } catch (_) {
        // Preserve the network error when the cache is unavailable.
      }
      Error.throwWithStackTrace(error, stack);
    }
    try {
      await CatalogCache.write(cacheKey, data);
    } catch (_) {
      // Storage failures should not hide a successful response.
    }
    return data;
  }

  Future<Map<String, dynamic>> _download(Uri url) async {
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('YTS returned HTTP ${response.statusCode}');
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['status'] != 'ok') throw Exception('YTS could not complete the request');
    return result['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<Movie>> search(String term) async {
    if (preview) {
      return samples.where((movie) => movie.title.toLowerCase().contains(term.toLowerCase())).toList();
    }
    return listMovies({'limit': '20', 'query_term': term});
  }

  @override
  Future<List<Movie>> homeMovies({required bool action}) {
    return listMovies({'limit': '20', 'sort_by': 'date_added', 'order_by': 'desc', if (action) 'genre': 'action'});
  }

  @override
  Future<List<Movie>> listMovies(Map<String, String> query) async {
    final data = await request('list_movies', query);
    if (data['movie_count'] == 0) return [];
    final rows = data['movies'] as List;
    return rows.map((row) => Movie.fromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Movie>> similar(int id) async {
    if (preview) return [];
    final data = await request('movie_suggestions', {'movie_id': id.toString()});
    final rows = data['movies'] as List? ?? [];
    return rows.map((row) => Movie.fromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<Movie> details(int id) async {
    if (preview) return samples.firstWhere((movie) => movie.id == id);
    final data = await request('movie_details', {'movie_id': id.toString(), 'with_cast': 'true', 'with_images': 'true'});
    return Movie.fromJson(data['movie'] as Map<String, dynamic>);
  }
}
