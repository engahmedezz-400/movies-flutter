import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
export 'package:flutter_bloc/flutter_bloc.dart' show BlocBuilder;

class CatalogRequest<T> {
  final Future<T> Function()? fetch;
  const CatalogRequest(this.fetch);
}

class CatalogBloc<T> extends Bloc<CatalogRequest<T>, AsyncSnapshot<T>> {
  int _generation = 0;

  CatalogBloc() : super(AsyncSnapshot<T>.nothing()) {
    on<CatalogRequest<T>>((request, emit) async {
      final generation = ++_generation;
      final fetch = request.fetch;
      if (fetch == null) {
        emit(AsyncSnapshot<T>.nothing());
        return;
      }
      emit(AsyncSnapshot<T>.waiting());
      try {
        final data = await fetch();
        if (generation == _generation && !emit.isDone) {
          emit(AsyncSnapshot<T>.withData(ConnectionState.done, data));
        }
      } catch (error, stack) {
        if (generation == _generation && !emit.isDone) {
          emit(AsyncSnapshot<T>.withError(ConnectionState.done, error, stack));
        }
      }
    });
  }

  void load(Future<T> Function() fetch) => add(CatalogRequest<T>(fetch));
  void reset() => add(CatalogRequest<T>(null));
}
