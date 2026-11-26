import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';

class ScanPdfScreen extends StatefulWidget {
  const ScanPdfScreen({super.key});
  @override
  State<ScanPdfScreen> createState() => _ScanPdfScreenState();
}

class _ScanPdfScreenState extends State<ScanPdfScreen> {
  final _pdfService = PdfService();
  final _picker = ImagePicker();
  File? _captured;
  File? _result;
  bool _busy = false;
  String? _error;
  String _title = '';

  Future<void> _capture() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (img != null) {
        setState(() { _captured = File(img.path); _error = null; _result = null; });
      }
    } catch (e) {
      setState(() => _error = 'Error al abrir camara: $e');
    }
  }

  Future<void> _pickGallery() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (img != null) {
        setState(() { _captured = File(img.path); _error = null; _result = null; });
      }
    } catch (e) {
      setState(() => _error = 'Error al seleccionar imagen: $e');
    }
  }

  Future<void> _scan() async {
    if (_captured == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final out = await _pdfService.createPdfFromImage(_captured!, title: _title.isEmpty ? null : _title);
      setState(() { _result = out; _busy = false; });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _busy = false; });
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(_result!.path)], title: 'PDF escaneado'));
  }

  void _clear() => setState(() { _captured = null; _result = null; _error = null; _title = ''; });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📸 Escanear PDF'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_captured == null) ...[
            _buildPlaceholder(),
            const SizedBox(height: 20),
            _buildCaptureButtons(),
          ] else ...[
            _buildPreview(),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Titulo (opcional)', prefixIcon: Icon(Icons.title)), onChanged: (v) => _title = v),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: SizedBox(height: 48, child: ElevatedButton.icon(
                onPressed: _busy ? null : _scan,
                icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.document_scanner),
                label: Text(_busy ? 'Creando PDF...' : 'Crear PDF'),
              ))),
              const SizedBox(width: 10),
              OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.refresh), label: const Text('Otra')),
            ]),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.bubbleCoral, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.bubbleCoralDark),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.bubbleCoralDark, fontSize: 13))),
              ])),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.bubbleMint, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                const Icon(Icons.check_circle, color: AppTheme.bubbleMintDark, size: 44),
                const SizedBox(height: 8),
                const Text('PDF creado!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text(_result!.path.split('/').last, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 14),
                SizedBox(height: 46, child: ElevatedButton.icon(onPressed: _share, icon: const Icon(Icons.share), label: const Text('Compartir'))),
              ])),
          ],
        ]),),);
  }

  Widget _buildPlaceholder() {
    return Container(height: 240, decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow, border: Border.all(color: AppTheme.pink200.withValues(alpha: 0.5))),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.bubblePink,
            boxShadow: AppTheme.bubbleGlow(AppTheme.bubblePinkDark)),
          child: const Icon(Icons.document_scanner, size: 36, color: AppTheme.bubblePinkDark)),
        const SizedBox(height: 16),
        const Text('Captura un documento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Usa la camara o selecciona una imagen', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ])),);
  }

  Widget _buildCaptureButtons() {
    return Row(children: [
      Expanded(child: _BubbleButton(icon: Icons.camera_alt, label: 'Camara',
          bubble: AppTheme.bubbleCoral, dark: AppTheme.bubbleCoralDark, onTap: _capture)),
      const SizedBox(width: 12),
      Expanded(child: _BubbleButton(icon: Icons.photo_library, label: 'Galeria',
          bubble: AppTheme.bubbleBlue, dark: AppTheme.bubbleBlueDark, onTap: _pickGallery)),
    ]);
  }

  Widget _buildPreview() {
    return ClipRRect(borderRadius: BorderRadius.circular(20),
      child: Container(constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(color: AppTheme.white, boxShadow: AppTheme.softShadow, borderRadius: BorderRadius.circular(20)),
        child: Image.file(_captured!, fit: BoxFit.contain),),);
  }
}

class _BubbleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bubble;
  final Color dark;
  final VoidCallback onTap;
  const _BubbleButton({required this.icon, required this.label, required this.bubble, required this.dark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.softShadow),
        child: Column(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: bubble, boxShadow: AppTheme.bubbleGlow(dark)),
            child: Icon(icon, color: dark, size: 28)),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),),);
  }
}