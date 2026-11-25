import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/home_screen.dart';

void main() {
  runApp(const KawaiiPdfApp());
}

/// Aplicación de manipulación de PDFs — kawaii pdf 🌸.
class KawaiiPdfApp extends StatelessWidget {
  const KawaiiPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kawaii pdf — Herramientas PDF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}

