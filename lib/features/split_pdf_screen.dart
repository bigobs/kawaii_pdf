import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});
  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  final _pdfService = PdfService();
  File? _selectedFile;
  int? _pageCount;
  bool _isProcessing = false;
  List<File>? _splitFiles;
  String? _error;
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _fromCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (f != null && f.path != null) {
      final file = File(f.path!);
      try {
        final count = await _pdfService.getPageCount(file);
        setState(() {
          _selectedFile = file; _pageCount = count;
          _splitFiles = null; _error = null;
        });
      } catch (e) {
        setState(() { _selectedFile = file; _error = 'Error: $e'; });
      }
    }
  }

  Future<void> _splitAll() async {
    if (_selectedFile == null) return;
    setState(() { _isProcessing = true; _error = null; });
    try {
      final files = await _pdfService.splitPdfAllPages(_selectedFile!);
      setState(() { _splitFiles = files; _isProcessing = false; });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _isProcessing = false; });
    }
  }

  Future<void> _splitFromPage() async {
    if (_selectedFile == null) return;
    final p = int.tryParse(_fromCtrl.text);
    if (p == null || p < 1) {
      setState(() => _error = 'Ingresa un número de página válido.'); return;
    }
    if (_pageCount != null && p > _pageCount!) {
      setState(() => _error = 'El documento tiene $_pageCount páginas.'); return;
    }
    setState(() { _isProcessing = true; _error = null; });
    try {
      final file = await _pdfService.splitPdfFromPage(_selectedFile!, p - 1);
      setState(() { _splitFiles = [file]; _isProcessing = false; });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _isProcessing = false; });
    }
  }

  Future<void> _splitRange() async {
    if (_selectedFile == null) return;
    final s = int.tryParse(_startCtrl.text);
    final e = int.tryParse(_endCtrl.text);
    if (s == null || e == null || s < 1 || e < s) {
      setState(() => _error = 'Rango invalido (ej: 1-3).'); return;
    }
    if (_pageCount != null && e > _pageCount!) {
      setState(() => _error = 'Excede $_pageCount paginas.'); return;
    }
    setState(() { _isProcessing = true; _error = null; });
    try {
      final file = await _pdfService.splitPdfRange(
        file: _selectedFile!, startPage: s - 1, endPage: e - 1);
      setState(() { _splitFiles = [file]; _isProcessing = false; });
    } catch (ex) {
      setState(() { _error = 'Error: $ex'; _isProcessing = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    final name = _selectedFile?.path.split('/').last ?? 'Ningun archivo';
    return Scaffold(
      appBar: AppBar(title: const Text('Dividir PDF')),
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
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: AppTheme.coral, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (_pageCount != null)
                            Text('$_pageCount paginas',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                        ],
                      ),
                    ),
                    ElevatedButton(onPressed: _pickFile, child: const Text('Seleccionar')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile != null) ...[
              const Text('Dividir todas las paginas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Cada pagina sera un PDF independiente.'),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _splitAll,
                  icon: _isProcessing
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.call_split),
                  label: const Text('Dividir todas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Extraer rango',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Inicio', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('a', style: TextStyle(fontSize: 18)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _endCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fin', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _splitRange,
                  icon: const Icon(Icons.content_cut),
                  label: const Text('Extraer rango'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Dividir desde pagina',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Extrae desde la pagina indicada hasta el final.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Desde pagina N°',
                        border: OutlineInputBorder(),
                        isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _splitFromPage,
                    icon: const Icon(Icons.call_split_rounded, size: 18),
                    label: const Text('Dividir'),
                  ),
                ),
              ],
            ),


            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
                child: Text(_error!,
                    style: const TextStyle(color: AppTheme.coral)),
              ),
            ],
            if (_splitFiles != null && _splitFiles!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.pink600),
                        SizedBox(width: 8),
                        Text('PDF dividido!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.pink600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(_splitFiles!.map((f) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.insert_drive_file, size: 20),
                          title: Text(f.path.split('/').last,
                              style: const TextStyle(fontSize: 13)),
                          trailing: IconButton(
                            icon: const Icon(Icons.share_rounded,
                                size: 20, color: AppTheme.pink500),
                            onPressed: () => SharePlus.instance.share(
                              ShareParams(files: [XFile(f.path)]),
                            ),
                          ),
                        ))),
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
