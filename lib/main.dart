import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/dictionary_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DictionaryProvider(),
      child: Consumer<DictionaryProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Dictionary App',
            // Define the light theme
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
              cardColor: Colors.white, // Changed to white for light mode
              useMaterial3: true,
            ),
            // Define the dark theme
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
              cardColor: Colors.black, // Changed to black for dark mode
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
