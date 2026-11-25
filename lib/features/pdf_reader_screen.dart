import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../core/theme.dart';

/// Lector de PDF a pantalla completa con navegación y zoom.
class PdfReaderScreen extends StatefulWidget {
  /// Si se proporciona [filePath], se abre directamente ese archivo.
  final String? filePath;

  const PdfReaderScreen({super.key, this.filePath});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  String? _pdfPath;
  bool _loading = false;
  String? _error;
  bool _fullscreen = false;
  final GlobalKey<SfPdfViewerState> _viewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.filePath != null) {
      _pdfPath = widget.filePath;
    } else {
      _pickFile();
    }
  }

  Future<void> _pickFile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result.isNotEmpty) {
        setState(() {
          _pdfPath = result.single.path;
          _loading = false;
        });
      } else {
        if (mounted) { setState(() => _loading = false); Navigator.pop(context); }
      }
    } catch (e) {
      setState(() { _error = 'Error al abrir el archivo: $e'; _loading = false; });
    }
  }

  void _toggleFullscreen() => setState(() => _fullscreen = !_fullscreen);

  @override
  Widget build(BuildContext context) {
    if (_pdfPath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('📖 Leer PDF')),
        body: _buildLoadingOrError(),
      );
    }

    return Scaffold(
      backgroundColor: _fullscreen ? Colors.black : null,
      extendBodyBehindAppBar: _fullscreen,
      appBar: _fullscreen
          ? null
          : AppBar(
              title: const Text('📖 Leer PDF'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.folder_open_rounded),
                  tooltip: 'Abrir otro PDF',
                  onPressed: _pickFile,
                ),
              ],
            ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(_pdfPath!),
            key: _viewerKey,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: true,
            onDocumentLoadFailed: (details) {
              setState(() => _error = 'No se pudo cargar: ${details.description}');
            },
          ),
          if (!_fullscreen)
            Positioned(
              bottom: 16, right: 16,
              child: FloatingActionButton.small(
                heroTag: 'fullscreen',
                backgroundColor: AppTheme.pink500,
                onPressed: _toggleFullscreen,
                child: const Icon(Icons.fullscreen_rounded, color: Colors.white),
              ),
            ),
          if (_fullscreen)
            Positioned(
              bottom: 16, right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'exit_fullscreen',
                    backgroundColor: AppTheme.pink500,
                    onPressed: _toggleFullscreen,
                    child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'open_file_fs',
                    backgroundColor: AppTheme.pink500,
                    onPressed: _pickFile,
                    child: const Icon(Icons.folder_open_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          if (_loading || _error != null) _buildLoadingOrError(),
        ],
      ),
    );
  }

  Widget _buildLoadingOrError() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.pink500),
            SizedBox(height: 16),
            Text('Abriendo PDF...', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.coral.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.coral, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.coral)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coral,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
