import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'account/account_service.dart';
import 'account/firebase_account_service.dart';
import 'data/set_repository.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'state/set_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AccountService? account;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    account = FirebaseAccountService();
  } catch (_) {
    // Without Firebase the app still works fully on the device.
  }
  runApp(EasyFlashcardsApp(repository: LocalSetRepository(), account: account));
}

class EasyFlashcardsApp extends StatelessWidget {
  const EasyFlashcardsApp({super.key, required this.repository, this.account});

  final SetRepository repository;

  /// Null hides the account feature (tests, or Firebase unavailable).
  final AccountService? account;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AccountService?>.value(value: account),
        ChangeNotifierProvider(
          create: (_) => SetStore(repository, account: account)..load(),
        ),
      ],
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
