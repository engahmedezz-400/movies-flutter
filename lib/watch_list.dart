import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/favorites/data/firestore_favorites.dart';
import 'features/favorites/presentation/watchlist_bloc.dart';
import 'movies.dart';

class FavoritesView extends StatelessWidget {
  final String uid;
  final Widget Function(BuildContext, List<Movie>, bool) builder;
  const FavoritesView({super.key, required this.uid, required this.builder});

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(uid),
    create: (_) => WatchlistBloc(FirestoreFavorites(uid))..add(LoadFavorites()),
    child: BlocConsumer<WatchlistBloc, WatchlistState>(
      listener: (context, state) {
        if (state.movies != null && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final movies = state.movies;
        if (movies != null) return builder(context, movies, state.saving);
        if (state.error != null) {
          return TextButton(onPressed: () => context.read<WatchlistBloc>().add(LoadFavorites()),
            child: Text(state.error!));
        }
        return const SizedBox.square(dimension: 24, child: CircularProgressIndicator());
      },
    ),
  );
}

class BookmarkButton extends StatelessWidget {
  final String uid;
  final Movie movie;
  const BookmarkButton({super.key, required this.uid, required this.movie});

  @override
  Widget build(BuildContext context) => FavoritesView(uid: uid,
    builder: (context, movies, busy) {
      final saved = movies.any((item) => item.id == movie.id);
      return IconButton(
        tooltip: saved ? 'Remove from Watch List' : 'Add to Watch List',
        onPressed: busy ? null : () => context.read<WatchlistBloc>().add(SetFavorite(movie, !saved)),
        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: Colors.amber),
      );
    });
}
