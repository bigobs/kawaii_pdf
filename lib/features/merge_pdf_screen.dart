import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});
  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final _pdfService = PdfService();
  final List<File> _selectedFiles = [];
  bool _isProcessing = false;
  File? _mergedFile;
  String? _error;

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(
          result.where((f) => f.path != null).map((f) => File(f.path!)),
        );
        _mergedFile = null;
        _error = null;
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _mergePdfs() async {
    if (_selectedFiles.length < 2) {
      setState(() => _error = 'Selecciona al menos 2 archivos PDF.');
      return;
    }
    setState(() { _isProcessing = true; _error = null; });
    try {
      final file = await _pdfService.mergePdfs(files: _selectedFiles);
      setState(() { _mergedFile = file; _isProcessing = false; });
    } catch (e) {
      setState(() { _error = 'Error al unir PDFs: $e'; _isProcessing = false; });
    }
  }

  Future<void> _sharePdf() async {
    if (_mergedFile == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(_mergedFile!.path)], title: 'PDF Unido'),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unir PDFs')),
      body: Column(
        children: [
          if (_selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${_selectedFiles.length} archivos seleccionados',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ),
          Expanded(
            child: _selectedFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            size: 64, color: AppTheme.pink200),
                        const SizedBox(height: 16),
                        const Text('No hay archivos seleccionados',
                            style: TextStyle(
                                fontSize: 16, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedFiles.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf_rounded,
                            color: AppTheme.coral),
                        title: Text(file.path.split('/').last,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Posicion ${index + 1}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppTheme.coral),
                          onPressed: () => _removeFile(index),
                        ),
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!,
                  style: const TextStyle(color: AppTheme.coral)),
            ),
          if (_mergedFile != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.pink600),
                    const SizedBox(width: 8),
                    const Expanded(
                        child: Text('PDFs unidos!',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.pink600))),
                    IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: AppTheme.pink500),
                      onPressed: _sharePdf,
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar PDFs'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isProcessing || _selectedFiles.length < 2 ? null : _mergePdfs,
                      icon: _isProcessing
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.merge),
                      label: const Text('Unir PDFs'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
