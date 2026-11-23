import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../movies.dart';
import '../domain/favorites_repository.dart';

class FirestoreFavorites implements FavoritesRepository {
  final String uid;
  FirestoreFavorites(this.uid);

  CollectionReference<Map<String, dynamic>> get favorites =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites');

  static final migrations = <String, Future<void>>{};

  Future<void> _importLocal() async {
    final prefs = SharedPreferencesAsync();
    final prefix = 'watch.$uid.';
    for (final key in await prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final value = await prefs.getString(key);
      if (value == null) continue;
      final row = jsonDecode(value) as Map<String, dynamic>;
      final movie = Movie.fromJson(row);
      if (key != '$prefix${movie.id}') continue;
      final doc = favorites.doc(movie.id.toString());
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (!(await transaction.get(doc)).exists) {
          transaction.set(doc, row);
        }
      });
      await prefs.remove(key);
    }
  }

  @override
  Stream<List<Movie>> watch() async* {
    await migrations.putIfAbsent(uid, () => _importLocal().whenComplete(() {
      migrations.remove(uid);
    }));
    yield* favorites.orderBy('title').snapshots().map((result) =>
        result.docs.map((doc) => Movie.fromJson(doc.data())).toList());
  }

  @override
  Future<void> setSaved(Movie movie, bool saved) {
    final doc = favorites.doc(movie.id.toString());
    if (!saved) return doc.delete();
    return doc.set({
      'id': movie.id, 'title': movie.title, 'year': movie.year,
      'rating': movie.rating, 'medium_cover_image': movie.poster,
      'description_full': movie.summary,
    });
  }
}
