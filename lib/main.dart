import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/dictionary_provider.dart';
import 'providers/game_provider.dart';
import 'providers/hangman_provider.dart';
import 'providers/word_puzzle_provider.dart';
import 'providers/download_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  final initialThemeMode =
      savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

  runApp(MyApp(initialThemeMode: initialThemeMode));
}

class MyApp extends StatelessWidget {
  final ThemeMode initialThemeMode;
  const MyApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) =>
              DictionaryProvider(initialThemeMode: initialThemeMode),
        ),
        ChangeNotifierProvider(create: (context) => GameProvider()),
        ChangeNotifierProvider(create: (context) => HangmanProvider()),
        ChangeNotifierProvider(create: (context) => WordPuzzleProvider()),
        ChangeNotifierProvider(create: (context) => DownloadProvider()),
      ],
      child: Consumer<DictionaryProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Dictionary App',
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: const Color(0xFFEFEBE0),
              fontFamily: 'Avenir',
              textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'Avenir',
                fontFamilyFallback: ['NotoSans'],
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                  fontFamily: 'Avenir',
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              cardColor: Colors.white,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: const Color(0xFF262626),
              fontFamily: 'Avenir',
              textTheme: Theme.of(context).primaryTextTheme.apply(
                fontFamily: 'Avenir',
                fontFamilyFallback: ['NotoSans'],
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(
                  fontFamily: 'Avenir',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              cardColor: Colors.black,
              useMaterial3: true,
            ),
            themeMode: provider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
