import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/set_repository.dart';
import 'screens/home_screen.dart';
import 'state/set_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EasyFlashcardsApp(repository: LocalSetRepository()));
}

class EasyFlashcardsApp extends StatelessWidget {
  const EasyFlashcardsApp({super.key, required this.repository});

  final SetRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SetStore(repository)..load(),
      child: MaterialApp(
        title: 'Easy Flashcards & Quiz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
