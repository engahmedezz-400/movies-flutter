import 'package:flutter/material.dart';
import 'movies.dart';
import 'screens.dart';

void main() => runApp(MaterialApp(theme: ThemeData.dark(), home: const MoviesHome(catalog: MovieCatalog(preview: true))));
