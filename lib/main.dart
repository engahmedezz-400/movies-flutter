import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'movies.dart';
import 'screens.dart';
import 'profile.dart';
import 'home.dart';
import 'browse.dart';
import 'startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(theme: ThemeData.dark(), home: const Startup(destination: AccountGate())));
}

class AccountGate extends StatelessWidget {
  const AccountGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    return StreamBuilder<User?>(stream: auth.authStateChanges(), builder: (context, state) {
      if (state.hasError) return const Scaffold(body: Center(child: Text('Could not read your session. Restart the app.')));
      if (state.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (state.data == null) return const LoginScreen();
      return AccountPages(key: ValueKey(state.data!.uid), user: state.data!);
    });
  }
}

class AccountPages extends StatefulWidget {
  final User user;
  const AccountPages({super.key, required this.user});

  @override
  State<AccountPages> createState() => _AccountPagesState();
}

class _AccountPagesState extends State<AccountPages> {
  int selected = 0;
  bool searchOpened = false;
  bool browseOpened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selected, children: [
        const HomePage(),
        if (searchOpened) MoviesHome(catalog: const MovieCatalog(), signOut: FirebaseAuth.instance.signOut) else const SizedBox.shrink(),
        if (browseOpened) const BrowsePage() else const SizedBox.shrink(),
        if (selected == 3) ProfilePage(user: widget.user) else const SizedBox.shrink(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() { selected = index; if (index == 1) searchOpened = true; if (index == 2) browseOpened = true; }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
