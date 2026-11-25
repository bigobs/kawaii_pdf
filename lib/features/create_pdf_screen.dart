import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';

/// Pantalla para crear un PDF nuevo.
class CreatePdfScreen extends StatefulWidget {
  const CreatePdfScreen({super.key});

  @override
  State<CreatePdfScreen> createState() => _CreatePdfScreenState();
}

class _CreatePdfScreenState extends State<CreatePdfScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  final _pdfService = PdfService();
  bool _isCreating = false;
  File? _createdFile;
  String? _error;

  // Formato
  bool _isBold = false;
  bool _isItalic = false;
  double _fontSize = 12;
  String _fontFamily = 'Helvetica';

  // Import
  bool _showImport = false;
  bool _importingUrl = false;
  bool _importingFile = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _createPdf() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = 'Por favor, completa título y contenido.');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
      _createdFile = null;
    });

    try {
      final file = await _pdfService.createPdf(
        title: title,
        content: content,
        isBold: _isBold,
        isItalic: _isItalic,
        fontSize: _fontSize,
        fontFamily: _fontFamily,
      );
      setState(() {
        _createdFile = file;
        _isCreating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al crear el PDF: $e';
        _isCreating = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_createdFile == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_createdFile!.path)],
        title: 'Compartir PDF',
      ),
    );
  }

  Future<void> _importFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Ingresa una URL.'); return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      setState(() => _error = 'URL invalida.'); return;
    }
    setState(() { _importingUrl = true; _error = null; });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = const Utf8Decoder().convert(res.bodyBytes);
        final text = body
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();
        setState(() {
          _contentController.text = text;
          _importingUrl = false;
          _showImport = false;
        });
      } else {
        setState(() { _error = 'Error ${res.statusCode}'; _importingUrl = false; });
      }
    } catch (e) {
      setState(() { _error = 'Error de conexion: $e'; _importingUrl = false; });
    }
  }

  Future<void> _importFromFile() async {
    setState(() { _importingFile = true; _error = null; });
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom, allowedExtensions: ['txt', 'csv', 'md']);
      if (f != null && f.path != null) {
        final content = await File(f.path!).readAsString();
        final name = f.path!.split('/').last;
        setState(() {
          _contentController.text = content;
          if (_titleController.text.isEmpty) {
            _titleController.text = name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
          _importingFile = false;
          _showImport = false;
        });
      } else {
        setState(() => _importingFile = false);
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _importingFile = false; });
    }
  }

  Widget _fmtBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final c = activeColor ?? AppTheme.pink500;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(color: c.withValues(alpha: 0.4))
              : Border.all(color: AppTheme.pink200.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 20,
            color: active ? c : AppTheme.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del documento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 14),
            // Toolbar de formato
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.pink200),
              ),
              child: Row(
                children: [
                  _fmtBtn(
                    icon: Icons.format_bold_rounded,
                    active: _isBold,
                    onTap: () => setState(() => _isBold = !_isBold),
                  ),
                  const SizedBox(width: 4),
                  _fmtBtn(
                    icon: Icons.format_italic_rounded,
                    active: _isItalic,
                    onTap: () => setState(() => _isItalic = !_isItalic),
                  ),
                  const Spacer(),
                  Text('Tamano:',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 75,
                    child: DropdownButtonFormField<double>(
                      initialValue: _fontSize, isDense: true,
                      decoration: const InputDecoration(border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
                      style: const TextStyle(fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 10.0, child: Text('10')),
                        DropdownMenuItem(value: 12.0, child: Text('12')),
                        DropdownMenuItem(value: 14.0, child: Text('14')),
                        DropdownMenuItem(value: 16.0, child: Text('16')),
                        DropdownMenuItem(value: 18.0, child: Text('18')),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _fontSize = v); },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      initialValue: _fontFamily, isDense: true,
                      decoration: const InputDecoration(border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
                      style: const TextStyle(fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: 'Helvetica', child: Text('Helvetica')),
                        DropdownMenuItem(value: 'Courier', child: Text('Courier')),
                        DropdownMenuItem(value: 'Times', child: Text('Times')),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _fontFamily = v); },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields_rounded),
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              minLines: 6,
            ),
            const SizedBox(height: 14),
            // Importar
            InkWell(
              onTap: () => setState(() => _showImport = !_showImport),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.pink200.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(_showImport ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20, color: AppTheme.pink400),
                  const SizedBox(width: 8),
                  Text('Importar contenido desde...',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ]),
              ),
            ),
            if (_showImport) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (pagina web)', hintText: 'https://ejemplo.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link_rounded), isDense: true,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              SizedBox(height: 40, child: OutlinedButton.icon(
                onPressed: _importingUrl ? null : _importFromUrl,
                icon: _importingUrl
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_download_rounded, size: 18),
                label: Text(_importingUrl ? 'Cargando...' : 'Importar desde URL'),
              )),
              const SizedBox(height: 10),
              SizedBox(height: 40, child: OutlinedButton.icon(
                onPressed: _importingFile ? null : _importFromFile,
                icon: _importingFile
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.folder_open_rounded, size: 18),
                label: Text(_importingFile ? 'Cargando...' : 'Importar archivo (.txt)'),
              )),
            ],
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.coral),
                ),
              ),
            if (_createdFile != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.mint.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.pink600, size: 48),
                    const SizedBox(height: 8),
                    const Text('¡PDF creado!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.pink600)),
                    const SizedBox(height: 4),
                    Text(_createdFile!.path.split('/').last,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Compartir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createPdf,
                child: _isCreating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('✨ Crear PDF', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
