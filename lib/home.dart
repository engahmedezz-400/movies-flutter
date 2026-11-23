import 'features/catalog/presentation/catalog_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'movies.dart';
import 'screens.dart';
import 'home_titles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool signingOut = false;

  Future<void> logout() async {
    if (signingOut) return;
    setState(() { signingOut = true; });
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log out. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() { signingOut = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff121312),
    appBar: AppBar(
      backgroundColor: const Color(0xff121312),
      toolbarHeight: 48,
      actions: [
        TextButton.icon(
          onPressed: signingOut ? null : logout,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: TextButton.styleFrom(foregroundColor: Colors.amber),
        ),
      ],
    ),
    body: SafeArea(child: ListView(children: const [
      HomeSection(action: false),
      HomeSection(action: true),
    ])),
  );
}

class HomeSection extends StatefulWidget {
  final bool action;
  const HomeSection({super.key, required this.action});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  final MovieRepository catalog = const MovieCatalog();
  final pages = PageController(viewportFraction: 0.64);
  late final films = CatalogBloc<List<Movie>>()..load(() => catalog.homeMovies(action: widget.action));
  int selected = 0;

  @override
  void dispose() {
    films.close();
    pages.dispose();
    super.dispose();
  }

  void open(Movie movie) {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => MovieDetails(catalog: catalog, id: movie.id)));
  }

  Widget card(Movie movie) => Semantics(button: true, label: '${movie.title}, rating ${movie.rating}',
    child: GestureDetector(onTap: () => open(movie), child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Color(0xff292929)),
        if (movie.poster.isNotEmpty) Image.network(movie.poster, fit: BoxFit.cover,
          errorBuilder: (_, error, stack) => Center(child: Text(movie.title, textAlign: TextAlign.center)))
        else Center(child: Text(movie.title, textAlign: TextAlign.center)),
        Positioned(top: 8, left: 8, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
          child: Text('★ ${movie.rating}', style: const TextStyle(color: Colors.amber)))),
      ]))));

  @override
  Widget build(BuildContext context) => BlocBuilder<CatalogBloc<List<Movie>>, AsyncSnapshot<List<Movie>>>(bloc: films, builder: (context, result) {
    if (result.connectionState != ConnectionState.done || result.hasError || result.requireData.isEmpty) {
      return SizedBox(height: 165, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(widget.action ? 'Action' : 'Available Now'),
        if (result.connectionState != ConnectionState.done) const CircularProgressIndicator()
        else if (result.hasError) TextButton(onPressed: () { setState(() { selected = 0; films.load(() => catalog.homeMovies(action: widget.action)); }); }, child: const Text('Try again'))
        else const Text('No movies available'),
      ]));
    }
    final movies = result.requireData;
    if (widget.action) {
      return Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          const Expanded(child: Text('Action', style: TextStyle(fontSize: 20))),
          TextButton(child: const Text('See more', style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) =>
              Scaffold(appBar: AppBar(title: const Text('Action')), body: GridView.builder(
                padding: const EdgeInsets.all(12), itemCount: movies.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180,
                  childAspectRatio: 0.67, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemBuilder: (_, i) => card(movies[i])))))),
        ])),
        SizedBox(height: 186, child: ListView.separated(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: movies.length,
          separatorBuilder: (_, i) => const SizedBox(width: 10),
          itemBuilder: (_, i) => SizedBox(width: 124, child: card(movies[i])))),
      ]);
    }
    final poster = movies[selected].poster;
    return Stack(children: [
      if (poster.isNotEmpty) Positioned.fill(child: Image.network(poster, fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => const SizedBox.shrink())),
      const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.black54, Colors.black54, Color(0xff121312)])))),
      Column(children: [
        Image.memory(availableTitle, height: 88, semanticLabel: 'Available Now'),
        SizedBox(height: (MediaQuery.sizeOf(context).width * 0.83).clamp(225.0, 385.0).toDouble(),
          child: PageView.builder(controller: pages, itemCount: movies.length,
            onPageChanged: (index) => setState(() { selected = index; }),
            itemBuilder: (_, i) => Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: i == selected ? 0 : 25),
              child: card(movies[i])))),
        Image.memory(watchTitle, height: 88, semanticLabel: 'Watch Now'),
      ]),
    ]);
  });
}
