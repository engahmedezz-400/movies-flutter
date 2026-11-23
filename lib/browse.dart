import 'features/catalog/presentation/catalog_bloc.dart';
import 'package:flutter/material.dart';
import 'movies.dart';
import 'screens.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  static const genres = ['Action', 'Adventure', 'Animation', 'Comedy', 'Crime',
    'Documentary', 'Drama', 'Family', 'Fantasy', 'Horror', 'Mystery',
    'Romance', 'Sci-Fi', 'Thriller', 'War', 'Western'];
  final MovieRepository catalog = const MovieCatalog();
  String genre = genres.first;
  late final films = CatalogBloc<List<Movie>>()..load(() => fetchMovies(genre));

  @override
  void dispose() {
    films.close();
    super.dispose();
  }

  Future<List<Movie>> fetchMovies(String value) => catalog.listMovies({
    'genre': value.toLowerCase(), 'limit': '20', 'sort_by': 'date_added', 'order_by': 'desc',
  });

  void choose(String value) {
    setState(() {
      genre = value;
      films.load(() => fetchMovies(value));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff121312),
    body: SafeArea(child: Column(children: [
      SizedBox(height: 56, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal, itemCount: genres.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final value = genres[i];
          return ChoiceChip(label: Text(value), selected: genre == value,
            selectedColor: Colors.amber, showCheckmark: false,
            labelStyle: TextStyle(color: genre == value ? Colors.black : Colors.amber),
            side: const BorderSide(color: Colors.amber),
            onSelected: (_) { if (genre != value) choose(value); });
        })),
      Expanded(child: BlocBuilder<CatalogBloc<List<Movie>>, AsyncSnapshot<List<Movie>>>(bloc: films, builder: (context, result) {
        if (result.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (result.hasError) return RetryLoad(retry: () => choose(genre));
        final movies = result.requireData;
        if (movies.isEmpty) return Center(child: Text('No movies found in $genre.'));
        return GridView.builder(key: ValueKey(genre), padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.67),
          itemCount: movies.length, itemBuilder: (context, i) {
            final movie = movies[i];
            return Semantics(button: true, label: '${movie.title}, rating ${movie.rating}',
              child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => MovieDetails(catalog: catalog, id: movie.id))),
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: Stack(fit: StackFit.expand, children: [
                    Poster(movie: movie, width: 145),
                    Positioned(top: 7, left: 7, child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(9)),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        child: Text('★ ${movie.rating}', style: const TextStyle(color: Colors.amber))))),
                  ]))));
          });
      })),
    ])),
  );
}
