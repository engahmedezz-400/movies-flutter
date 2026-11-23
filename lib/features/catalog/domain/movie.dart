class Movie {
  final int id;
  final String title;
  final String year;
  final String poster;
  final String rating;
  final String summary;

  final String trailer;
  final int minutes;
  final int? likes;
  final List<String> genres;
  final List<String> shots;
  final List<Map<String, dynamic>> cast;

  const Movie(this.id, this.title, this.year, this.poster, this.rating, this.summary,
    {this.trailer = '', this.minutes = 0, this.likes, this.genres = const [],
     this.shots = const [], this.cast = const []});

  factory Movie.fromJson(Map<String, dynamic> row) {
    return Movie(row['id'] as int, row['title'] as String,
        row['year']?.toString() ?? '', row['medium_cover_image'] ?? '',
        row['rating']?.toString() ?? '—', row['description_full'] ?? '',
        trailer: row['yt_trailer_code'] ?? '', minutes: row['runtime'] as int? ?? 0,
        likes: row['like_count'] as int?, genres: (row['genres'] as List? ?? []).whereType<String>().toList(),
        shots: [for (var i = 1; i <= 3; i++) row['large_screenshot_image$i'] ?? row['medium_screenshot_image$i']]
            .whereType<String>().where((url) => url.isNotEmpty).toList(),
        cast: (row['cast'] as List? ?? []).whereType<Map<String, dynamic>>().toList());
  }
}

