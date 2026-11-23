import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/movies.dart';
import 'package:movies_app/screens.dart';

void main() {
  testWidgets('Practice search, details, and empty results', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MoviesHome(catalog: MovieCatalog(preview: true))));
    await tester.pumpAndSettle();
    expect(find.text('The Last Frame'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cairo');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.text('The Last Frame'), findsNothing);
    final movieTitle = find.text('Midnight in Cairo');
    await tester.ensureVisible(movieTitle);
    await tester.pumpAndSettle();
    expect(movieTitle.hitTestable(), findsOneWidget);
    await tester.tap(movieTitle);
    await tester.pumpAndSettle();
    expect(find.text('Movie details'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No movies found'), findsOneWidget);
  });
}
