import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../movies.dart';
import '../domain/favorites_repository.dart';

sealed class WatchlistEvent {}
class LoadFavorites extends WatchlistEvent {}
class SetFavorite extends WatchlistEvent {
  final Movie movie;
  final bool saved;
  SetFavorite(this.movie, this.saved);
}

class WatchlistState {
  final List<Movie>? movies;
  final String? error;
  final bool saving;
  const WatchlistState(this.movies, {this.error, this.saving = false});
}

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(FavoritesRepository repository) : super(const WatchlistState(null)) {
    on<LoadFavorites>((event, emit) async {
      emit(const WatchlistState(null));
      try {
        await emit.forEach<List<Movie>>(repository.watch(),
          onData: (movies) => WatchlistState(movies, saving: state.saving));
      } catch (_) {
        emit(const WatchlistState(null, error: 'Could not load Watch List. Retry'));
      }
    });
    on<SetFavorite>((event, emit) async {
      if (state.saving || state.movies == null) return;
      emit(WatchlistState(state.movies, saving: true));
      try {
        await repository.setSaved(event.movie, event.saved);
        emit(WatchlistState(state.movies, error: state.error));
      } catch (_) {
        emit(WatchlistState(state.movies, error: 'Could not update Watch List. Try again.'));
      }
    });
  }
}
