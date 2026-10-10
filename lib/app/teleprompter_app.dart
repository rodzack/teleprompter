import 'package:flutter/material.dart';

import '../screens/library_page.dart';

class TeleprompterApp extends StatelessWidget {
  const TeleprompterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Teleprompter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF101310),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB7F36B),
            brightness: Brightness.dark,
            surface: const Color(0xFF1B201B),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const LibraryPage(),
      );
}
