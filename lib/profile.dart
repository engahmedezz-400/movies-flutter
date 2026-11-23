import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/account/data/firebase_account_repository.dart';
import 'features/account/presentation/account_cubit.dart';
import 'movie_history.dart';
import 'screens.dart';
import 'movies.dart';
import 'watch_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_avatars.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool history = false;
  bool clearing = false;

  Future<void> clearHistory() async {
    final uid = widget.user.uid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('Remove all movies from your history on this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Clear')),
        ],
      ),
    );
    if (!mounted || confirmed != true || widget.user.uid != uid || clearing) return;
    setState(() => clearing = true);
    try {
      await MovieHistory(uid).clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not clear history. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          clearing = false;
          savedMovies = loadMovies();
        });
      }
    }
  }

  Future<List<Movie>>? savedMovies;

  Future<List<Movie>> loadMovies() {
    return MovieHistory(widget.user.uid).movies();
  }

  late Future<List<String>?> details;

  @override
  void initState() {
    super.initState();
    details = loadDetails();
  }

  Future<List<String>?> loadDetails() {
    return SharedPreferencesAsync().getStringList('profile.${widget.user.uid}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff191919),
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(child: FutureBuilder<List<String>?>(
        future: details,
        builder: (context, result) {
          if (result.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.hasError) {
            return Center(child: TextButton(
              onPressed: () { setState(() { details = loadDetails(); }); },
              child: const Text('Could not read profile. Try again'),
            ));
          }
          final rows = result.data ?? const <String>[];
          final display = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
          final name = display.isNotEmpty ? display : (rows.isNotEmpty ? rows[0] : '');
          final phone = rows.length > 1 ? rows[1] : '';
          final avatar = rows.length > 2 ? int.tryParse(rows[2]) : null;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: avatar != null && avatar >= 0 && avatar < profileAvatars.length
              ? ClipOval(child: Image.memory(profileAvatars[avatar], width: 110, height: 110))
              : const CircleAvatar(radius: 55, child: Icon(Icons.person, size: 52))),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Name'),
              subtitle: Text(name.isEmpty ? 'Not provided' : name)),
            ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'),
              subtitle: Text(widget.user.email ?? 'Not provided')),
            ListTile(leading: const Icon(Icons.phone), title: const Text('Phone number'),
              subtitle: Text(phone.isEmpty ? 'Not saved on this device' : phone)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('Edit Profile'),
              onPressed: () async {
                await Navigator.push<void>(context, MaterialPageRoute(builder: (_) =>
                  EditProfile(uid: widget.user.uid, name: name, phone: phone, avatar: avatar)));
                if (mounted) setState(() { details = loadDetails(); });
              },
            ),
            const SizedBox(height: 20),
            Wrap(spacing: 8, children: [
              for (final showHistory in [false, true])
                ChoiceChip(label: Text(showHistory ? 'History' : 'Watch List'), selected: history == showHistory,
                  onSelected: (_) { setState(() { history = showHistory; if (history) savedMovies = loadMovies(); }); }),
            ]),
            if (!history)
              FavoritesView(uid: widget.user.uid, builder: (_, movies, _) => movieRows(movies))
            else
            FutureBuilder<List<Movie>>(future: savedMovies, builder: (context, result) {
              if (result.connectionState != ConnectionState.done) return const LinearProgressIndicator();
              if (result.hasError) {
                return TextButton(onPressed: () => setState(() { savedMovies = loadMovies(); }),
                  child: const Text('Could not load movies. Retry'));
              }
              final films = result.requireData;
              return movieRows(films);
            }),
          ]);
        },
      )),
    );
  }
  Widget movieRows(List<Movie> films) {
              if (films.isEmpty) return Text(history ? 'Open a movie to start your history.' : 'Your Watch List is empty.');
              return Column(children: [
                if (history)
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(
                    onPressed: clearing ? null : clearHistory,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear history'),
                  )),
                for (final film in films)
                  ListTile(leading: Poster(movie: film, width: 40), title: Text(film.title), subtitle: Text(film.year),
                    onTap: () async {
                      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) =>
                        MovieDetails(id: film.id, catalog: const MovieCatalog(), savedMovie: film)));
                      if (mounted && history) { setState(() { savedMovies = loadMovies(); }); }
                    }),
              ]);
  }

}

class EditProfile extends StatefulWidget {
  final String uid;
  final String name;
  final String phone;
  final int? avatar;
  const EditProfile({super.key, required this.uid, required this.name, required this.phone, this.avatar});
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late final name = TextEditingController(text: widget.name);
  late final phone = TextEditingController(text: widget.phone);
  late int? avatar = widget.avatar;
  final account = AccountCubit(FirebaseAccountRepository());

  @override
  void dispose() {
    account.close();
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final saved = await account.update(widget.uid, name.text.trim(), phone.text.trim(), avatar);
    if (mounted && saved) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(
    bloc: account, builder: (context, state) {
    final saving = state.busy;
    final message = state.message;
    return Scaffold(appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Choose your avatar'),
        Wrap(alignment: WrapAlignment.center, children: [
          for (int i = 0; i < profileAvatars.length; i++)
            Semantics(selected: avatar == i, label: 'Avatar ${i + 1}', child: IconButton(
              onPressed: saving ? null : () => setState(() { avatar = i; }),
              icon: CircleAvatar(radius: 29, backgroundColor: avatar == i ? Colors.amber : Colors.transparent,
                child: ClipOval(child: Image.memory(profileAvatars[i], width: 50, height: 50))))),
        ]),
        TextField(controller: name, enabled: !saving, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: phone, enabled: !saving, keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number')),
        const SizedBox(height: 20),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          onPressed: saving ? null : save, child: Text(saving ? 'Saving…' : 'Update Data')),
        if (message.isNotEmpty) Text(message),
      ])));
  });
}
