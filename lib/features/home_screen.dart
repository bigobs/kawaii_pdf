import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'create_pdf_screen.dart';
import 'merge_pdf_screen.dart';
import 'split_pdf_screen.dart';
import 'unlock_pdf_screen.dart';
import 'edit_pdf_screen.dart';
import 'pdf_reader_screen.dart';

/// Pantalla principal con el menu de herramientas PDF 🌸.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'pdf_reader',
        backgroundColor: AppTheme.pink500,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PdfReaderScreen()),
        ),
        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
      ),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌸 '),
            Text('kawaii pdf'),
            Text(' 🌸'),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppTheme.gradHero,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: AppTheme.pink700,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.cream, AppTheme.pink50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('✨ Herramientas PDF',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Selecciona una herramienta para tus documentos',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _KawaiiToolCard(
                      icon: Icons.note_add_rounded,
                      label: 'Crear PDF',
                      color: AppTheme.pink500,
                      description: 'Nuevo doc',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const CreatePdfScreen())),
                    ),
                    _KawaiiToolCard(
                      icon: Icons.merge_rounded,
                      label: 'Unir PDFs',
                      color: AppTheme.pink600,
                      description: 'Combinar',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const MergePdfScreen())),
                    ),
                    _KawaiiToolCard(
                      icon: Icons.call_split_rounded,
                      label: 'Dividir PDF',
                      color: AppTheme.coral,
                      description: 'Extraer',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const SplitPdfScreen())),
                    ),
                    _KawaiiToolCard(
                      icon: Icons.lock_open_rounded,
                      label: 'Desbloquear',
                      color: AppTheme.pink700,
                      description: 'Sin password',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const UnlockPdfScreen())),
                    ),
                    _KawaiiToolCard(
                      icon: Icons.edit_rounded,
                      label: 'Editar PDF',
                      color: AppTheme.lavender,
                      description: 'Watermark',
                      iconIsDark: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const EditPdfScreen(
                                  mode: EditMode.watermark))),
                    ),
                    _KawaiiToolCard(
                      icon: Icons.lock_rounded,
                      label: 'Proteger PDF',
                      color: AppTheme.peach,
                      description: 'Password',
                      iconIsDark: true,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const EditPdfScreen(
                                  mode: EditMode.protect))),
                    ),
                    _KawaiiToolCard(
                      icon: Icons.text_fields_rounded,
                      label: 'Modificar',
                      color: AppTheme.pink300,
                      description: 'Editar texto',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const EditPdfScreen(
                                  mode: EditMode.text))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Card kawaii individual con icono, label y descripcion.
class _KawaiiToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String description;
  final VoidCallback onTap;
  final bool iconIsDark;

  const _KawaiiToolCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
    required this.onTap,
    this.iconIsDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.kawaiiShadow,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.12),
          highlightColor: color.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: iconIsDark ? AppTheme.pink700 : color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
