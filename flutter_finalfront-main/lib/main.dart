import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recipesscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipes App',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 35, 34, 34),
        scaffoldBackgroundColor: Colors.black87,
        colorScheme: const ColorScheme.dark(
          primary: Colors.black,
          secondary: Colors.white,
          surface: Colors.grey,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 9, 9, 9),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.grey,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const RecipesScreen(),
    );
  }
}
