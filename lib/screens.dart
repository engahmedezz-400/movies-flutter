import 'features/catalog/presentation/catalog_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'movie_history.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'watch_list.dart';
import 'package:flutter/material.dart';
import 'movies.dart';

class MoviesHome extends StatefulWidget {
  final MovieRepository catalog;
  final Future<void> Function()? signOut;
  const MoviesHome({super.key, required this.catalog, this.signOut});

  @override
  State<MoviesHome> createState() => _MoviesHomeState();
}

class _MoviesHomeState extends State<MoviesHome> {
  final searchBox = TextEditingController();
  final films = CatalogBloc<List<Movie>>();
  static final emptyArt = base64Decode('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');

  @override
  void initState() {
    super.initState();
    if (widget.catalog.preview) films.load(() => widget.catalog.search(''));
  }

  @override
  void dispose() {
    films.close();
    searchBox.dispose();
    super.dispose();
  }

  void search() {
    final term = searchBox.text.trim();
    if (term.isEmpty && !widget.catalog.preview) {
      films.reset();
    } else {
      films.load(() => widget.catalog.search(term));
    }
  }

  Future<void> logout() async {
    try {
      await widget.signOut!();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not sign out. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.catalog.preview ? 'Movies · Practice' : 'Search'), actions: [
        if (widget.signOut != null) IconButton(onPressed: logout, icon: const Icon(Icons.logout), tooltip: 'Sign out')
      ]),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: searchBox, onChanged: (value) {
          if (value.trim().isEmpty && !widget.catalog.preview) films.reset();
        }, onSubmitted: (_) => search(), textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: 'Search', filled: true, fillColor: const Color(0xff282828), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), suffixIcon: IconButton(onPressed: search, icon: const Icon(Icons.search), tooltip: 'Search'))),
        const SizedBox(height: 12),
        Expanded(child: BlocBuilder<CatalogBloc<List<Movie>>, AsyncSnapshot<List<Movie>>>(bloc: films, builder: (context, result) {
          if (result.connectionState == ConnectionState.none) return Center(child: Image.memory(emptyArt, width: 112, semanticLabel: 'Search for a movie'));
          if (result.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (result.hasError) return RetryLoad(retry: search);
          final list = result.requireData;
          if (list.isEmpty) return const Center(child: Text('No movies found. Try another title.'));
          return GridView.builder(itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,
              childAspectRatio: 0.67, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemBuilder: (context, index) {
              final movie = list[index];
              return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => MovieDetails(catalog: widget.catalog, id: movie.id))),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(fit: StackFit.expand, children: [
                  Poster(movie: movie, width: 150),
                  Positioned(top: 6, left: 6, child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                      child: Text('★ ${movie.rating}', style: const TextStyle(color: Colors.amber))))),
                  Align(alignment: Alignment.bottomCenter, child: Container(width: double.infinity, color: Colors.black87,
                    padding: const EdgeInsets.all(5), child: Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis))),
                ])));
            });
        }))
      ]))),
    );
  }
}

class Poster extends StatelessWidget {
  final Movie movie;
  final double width;
  const Poster({super.key, required this.movie, required this.width});
  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: const Color(0xff233244), child: Center(child: Icon(Icons.movie_outlined, size: width / 2)));
    return SizedBox(width: width, height: width * 1.5, child: movie.poster.isEmpty ? placeholder :
      Image.network(movie.poster, fit: BoxFit.cover, errorBuilder: (_, error, stack) => placeholder));
  }
}

class RetryLoad extends StatelessWidget {
  final VoidCallback retry;
  const RetryLoad({super.key, required this.retry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('Could not load movies from YTS.'), TextButton(onPressed: retry, child: const Text('Try again'))
  ]));
}

class MovieDetails extends StatefulWidget {
  final MovieRepository catalog;
  final int id;
  final Movie? savedMovie;
  const MovieDetails({super.key, required this.catalog, required this.id, this.savedMovie});
  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  final film = CatalogBloc<Movie>();
  final suggestions = CatalogBloc<List<Movie>>();
  @override
  void initState() {
    super.initState();
    film.load(openMovie);
    suggestions.load(() => widget.catalog.similar(widget.id));
  }

  @override
  void dispose() {
    film.close();
    suggestions.close();
    super.dispose();
  }

  Future<Movie> openMovie() async {
    final uid = widget.catalog.preview ? null : FirebaseAuth.instance.currentUser?.uid;
    Movie movie;
    try {
      movie = await widget.catalog.details(widget.id);
    } catch (_) {
      if (widget.savedMovie == null) rethrow;
      movie = widget.savedMovie!;
    }
    if (mounted && uid != null && FirebaseAuth.instance.currentUser?.uid == uid) {
      try {
        await MovieHistory(uid).record(movie);
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this history entry.')));
      }
    }
    return movie;
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Movie details')),
    body: SafeArea(child: BlocBuilder<CatalogBloc<Movie>, AsyncSnapshot<Movie>>(bloc: film, builder: (context, result) {
      if (result.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (result.hasError) {
        return RetryLoad(retry: () => film.load(openMovie));
      }
      final movie = result.requireData;
      final uid = widget.catalog.preview ? null : FirebaseAuth.instance.currentUser?.uid;
      final heading = Theme.of(context).textTheme.titleLarge;
      return ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 24), children: [
        Stack(children: [
          Center(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Poster(movie: movie, width: 235))),
          if (uid != null) Align(alignment: Alignment.topRight, child: BookmarkButton(uid: uid, movie: movie)),
        ]),
        const SizedBox(height: 12),
        Text(movie.title, textAlign: TextAlign.center, style: heading),
        Text(movie.year, textAlign: TextAlign.center),
        if (movie.trailer.isNotEmpty) FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
          icon: const Icon(Icons.play_arrow), label: const Text('Watch trailer'),
          onPressed: () async {
            final url = Uri.https('www.youtube.com', '/watch', {'v': movie.trailer});
            try {
              if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
            } catch (_) {}
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open trailer.')));
          }),
        Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
          Chip(label: Text('★ ${movie.rating}')),
          if (movie.minutes > 0) Chip(label: Text('${movie.minutes} min')),
          if (movie.likes != null) Chip(label: Text('♥ ${movie.likes}')),
        ]),
        if (movie.shots.isNotEmpty) ...[
          Text('Screenshots', style: heading),
          for (final url in movie.shots) Padding(padding: const EdgeInsets.only(top: 6),
            child: Image.network(url, fit: BoxFit.fitWidth, errorBuilder: (_, e, st) => const SizedBox.shrink())),
        ],
        BlocBuilder<CatalogBloc<List<Movie>>, AsyncSnapshot<List<Movie>>>(bloc: suggestions, builder: (context, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Similar', style: heading),
            SizedBox(height: 150, child: ListView.separated(scrollDirection: Axis.horizontal,
              itemCount: items.length, separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Tooltip(message: items[i].title, child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) =>
                  MovieDetails(catalog: widget.catalog, id: items[i].id))),
                child: Poster(movie: items[i], width: 100))))),
          ]);
        }),
        Text('Summary', style: heading),
        Text(movie.summary.isEmpty ? 'No synopsis available.' : movie.summary),
        if (movie.cast.isNotEmpty) ...[
          Text('Cast', style: heading),
          for (final actor in movie.cast) ListTile(contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline), title: Text(actor['name']?.toString() ?? ''),
            subtitle: Text(actor['character_name']?.toString() ?? '')),
        ],
        if (movie.genres.isNotEmpty) ...[
          Text('Genres', style: heading),
          Wrap(spacing: 6, children: [for (final genre in movie.genres) Chip(label: Text(genre))]),
        ],
      ]);
    })));
}
