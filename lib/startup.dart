import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'startup_images.dart';

class Startup extends StatefulWidget {
  final Widget destination;
  const Startup({super.key, required this.destination});
  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  static const titles = ['Find Your Next Favorite Movie Here', 'Discover Movies',
    'Explore All Genres', 'Create Watchlists', 'Rate, Review, and Learn', 'Start Watching Now'];
  static const descriptions = [
    'Get access to a huge library of movies to suit all tastes.',
    'Discover new releases and find a film for tonight.',
    'Browse your favorite genres or try something different.',
    'Save movies to your watch list and come back to them later.',
    'Explore ratings, cast, and the story behind each film.', ''
  ];
  final prefs = SharedPreferencesAsync();
  bool loading = true;
  bool done = false;
  bool saving = false;
  String error = '';
  int index = 0;

  @override
  void initState() {
    super.initState();
    checkFirstRun();
  }

  Future<void> checkFirstRun() async {
    setState(() { loading = true; error = ''; });
    try {
      final seen = await prefs.getBool('onboarding.finished') ?? false;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() { done = seen && !const bool.fromEnvironment('PREVIEW_INTRO'); loading = false; });
    } catch (_) {
      if (mounted) setState(() { loading = false; error = 'Could not load your settings.'; });
    }
  }

  Future<void> next() async {
    if (index < titles.length - 1) {
      setState(() { index++; });
      return;
    }
    if (saving) return;
    setState(() { saving = true; });
    try {
      await prefs.setBool('onboarding.finished', true);
      if (mounted) setState(() { done = true; });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try Finish again.')));
      }
    } finally {
      if (mounted) setState(() { saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (done) return widget.destination;
    if (loading) {
      return Scaffold(backgroundColor: const Color(0xff181818),
      body: Center(child: Image.memory(startupLogo, width: 124, semanticLabel: 'Movies')));
    }
    if (error.isNotEmpty) {
      return Scaffold(body: Center(child: TextButton(
      onPressed: checkFirstRun, child: Text('$error Retry'))));
    }
    return Scaffold(backgroundColor: const Color(0xff141414), body: Stack(fit: StackFit.expand, children: [
      if (index == 0) ClipRect(child: LayoutBuilder(builder: (context, area) {
        final tileWidth = area.maxWidth * 0.47;
        final tileHeight = area.maxHeight * 0.34;
        return Transform.rotate(angle: -0.32, child: OverflowBox(
          minWidth: tileWidth * 3, maxWidth: tileWidth * 3,
          minHeight: tileHeight * 4, maxHeight: tileHeight * 4,
          child: Column(children: [
            for (int row = 0; row < 4; row++) Row(children: [
              for (int col = 0; col < 3; col++) SizedBox(width: tileWidth, height: tileHeight,
                child: Padding(padding: const EdgeInsets.all(3), child: Image.memory(introTiles[row * 3 + col], fit: BoxFit.cover))),
            ]),
          ]),
        ));
      })) else Image.memory(startupPoster(index), fit: BoxFit.cover, alignment: Alignment.topCenter),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black38, Colors.black]))),
      SafeArea(child: Align(alignment: Alignment.bottomCenter, child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: index == 0 ? Colors.transparent : const Color(0xff202020),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(titles[index], textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          if (descriptions[index].isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(descriptions[index], textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: saving ? null : next, child: Text(index == 0 ? 'Explore Now' : index == 5 ? 'Finish' : 'Next')),
          if (index > 0) OutlinedButton(onPressed: saving ? null : () => setState(() { index--; }),
            child: const Text('Back', style: TextStyle(color: Colors.amber))),
        ])),
      ))),
    ]));
  }
}
