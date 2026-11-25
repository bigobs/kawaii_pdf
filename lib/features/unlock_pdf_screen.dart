import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';

/// Pantalla para desbloquear un PDF protegido con contraseña.
class UnlockPdfScreen extends StatefulWidget {
  const UnlockPdfScreen({super.key});

  @override
  State<UnlockPdfScreen> createState() => _UnlockPdfScreenState();
}

class _UnlockPdfScreenState extends State<UnlockPdfScreen> {
  final _pdfService = PdfService();
  final _passwordController = TextEditingController();
  File? _selectedFile;
  bool _isEncrypted = false;
  bool _isProcessing = false;
  File? _unlockedFile;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.path != null) {
      final file = File(result.path!);
      setState(() {
        _selectedFile = file;
        _unlockedFile = null;
        _error = null;
        _isEncrypted = false;
      });

      try {
        final encrypted = await _pdfService.isPdfEncrypted(file);
        setState(() => _isEncrypted = encrypted);
      } catch (e) {
        setState(() => _error = 'Error al leer el archivo.');
      }
    }
  }

  Future<void> _unlockPdf() async {
    if (_selectedFile == null) return;
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _error = 'Ingresa la contraseña del PDF.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final file = await _pdfService.unlockPdf(_selectedFile!, password);
      setState(() {
        _isProcessing = false;
        if (file != null) {
          _unlockedFile = file;
        } else {
          _error = 'Contraseña incorrecta o error al desbloquear.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_unlockedFile == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_unlockedFile!.path)],
        title: 'PDF Desbloqueado',
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final fileName =
        _selectedFile?.path.split('/').last ?? 'Ningún archivo seleccionado';

    return Scaffold(
      appBar: AppBar(title: const Text('Desbloquear PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isEncrypted ? Icons.lock : Icons.picture_as_pdf_rounded,
                      color: _isEncrypted
                          ? AppTheme.coral
                          : AppTheme.pink600,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(
                            _isEncrypted
                                ? 'PDF protegido con contraseña'
                                : 'PDF sin protección',
                            style: TextStyle(
                                fontSize: 13,
                                color: _isEncrypted
                                    ? const Color(0xFFEA4335)
                                    : const Color(0xFF34A853)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Seleccionar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile != null && _isEncrypted) ...[
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña del PDF',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _unlockPdf,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: const Text('Desbloquear PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pink700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (_selectedFile != null && !_isEncrypted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: AppTheme.pink600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Este PDF no está protegido.',
                          style: TextStyle(color: AppTheme.pink600)),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: AppTheme.coral)),
              ),
            ],
            if (_unlockedFile != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.pink600, size: 48),
                    const SizedBox(height: 8),
                    const Text('¡PDF desbloqueado!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.pink600)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _sharePdf,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartir'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
