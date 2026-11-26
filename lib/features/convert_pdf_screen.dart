import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';

/// Pantalla para convertir un PDF a otros formatos (Word, Excel, PPT, TXT).
class ConvertPdfScreen extends StatefulWidget {
  const ConvertPdfScreen({super.key});
  @override
  State<ConvertPdfScreen> createState() => _ConvertPdfScreenState();
}

enum _ExportFormat { docx, xlsx, pptx, txt }

class _ConvertPdfScreenState extends State<ConvertPdfScreen> {
  final _pdfService = PdfService();
  File? _pdfFile;
  String? _pdfName;
  int? _pageCount;
  _ExportFormat _format = _ExportFormat.txt;
  bool _busy = false;
  String? _error;
  File? _resultFile;

  Future<void> _pickPdf() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (f != null && f.path != null) {
      final file = File(f.path!);
      final name = f.path!.split('/').last;
      setState(() { _pdfFile = file; _pdfName = name; _error = null; _resultFile = null; });
      try {
        final count = await _pdfService.getPageCount(file);
        setState(() => _pageCount = count);
      } catch (_) { setState(() => _pageCount = null); }
    }
  }

  Future<void> _convert() async {
    if (_pdfFile == null) return;
    setState(() { _busy = true; _error = null; _resultFile = null; });
    try {
      final base = _pdfName?.replaceAll(RegExp(r'\.[^.]+$'), '');
      File out;
      switch (_format) {
        case _ExportFormat.docx: out = await _pdfService.exportPdfToDocx(_pdfFile!, baseName: base);
        case _ExportFormat.xlsx: out = await _pdfService.exportPdfToXlsx(_pdfFile!, baseName: base);
        case _ExportFormat.pptx: out = await _pdfService.exportPdfToPptx(_pdfFile!, baseName: base);
        case _ExportFormat.txt:  out = await _pdfService.exportPdfToTxt(_pdfFile!, baseName: base);
      }
      setState(() { _resultFile = out; _busy = false; });
    } catch (e) { setState(() { _error = 'Error: $e'; _busy = false; }); }
  }

  Future<void> _share() async {
    if (_resultFile == null) return;
    await SharePlus.instance.share(ShareParams(
      files: [XFile(_resultFile!.path)], title: 'Compartir archivo'));
  }

  String get _formatLabel {
    switch (_format) {
      case _ExportFormat.docx: return 'Word (.docx)';
      case _ExportFormat.xlsx: return 'Excel (.xlsx)';
      case _ExportFormat.pptx: return 'PowerPoint (.pptx)';
      case _ExportFormat.txt:  return 'Texto (.txt)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔄 Convertir PDF'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_pdfFile == null) ...[
            const Icon(Icons.picture_as_pdf, size: 64, color: AppTheme.pink400),
            const SizedBox(height: 12),
            const Text('Selecciona un PDF para convertir', textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(height: 48, child: ElevatedButton.icon(
              onPressed: _pickPdf, icon: const Icon(Icons.folder_open),
              label: const Text('Abrir PDF'))),
          ] else ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
                color: AppTheme.pink50, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.picture_as_pdf, color: AppTheme.pink500, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_pdfName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_pageCount != null)
                    Text('$_pageCount páginas', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ])),
                IconButton(icon: const Icon(Icons.close), onPressed: () {
                  setState(() { _pdfFile = null; _pdfName = null; _pageCount = null; _resultFile = null; });
                }),
              ])),
            const SizedBox(height: 20),
            const Text('Formato de salida:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _FormatTile(selected: _format == _ExportFormat.docx,
              icon: Icons.description_outlined, label: 'Word (.docx)',
              onTap: () => setState(() => _format = _ExportFormat.docx)),
            const SizedBox(height: 8),
            _FormatTile(selected: _format == _ExportFormat.xlsx,
              icon: Icons.table_chart_outlined, label: 'Excel (.xlsx)',
              onTap: () => setState(() => _format = _ExportFormat.xlsx)),
            const SizedBox(height: 8),
            _FormatTile(selected: _format == _ExportFormat.pptx,
              icon: Icons.slideshow_outlined, label: 'PowerPoint (.pptx)',
              onTap: () => setState(() => _format = _ExportFormat.pptx)),
            const SizedBox(height: 8),
            _FormatTile(selected: _format == _ExportFormat.txt,
              icon: Icons.text_snippet_outlined, label: 'Texto (.txt)',
              onTap: () => setState(() => _format = _ExportFormat.txt)),
            const SizedBox(height: 16),
            SizedBox(height: 48, child: ElevatedButton.icon(
              onPressed: _busy ? null : _convert,
              icon: _busy ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.swap_horiz),
              label: Text(_busy ? 'Convirtiendo...' : 'Convertir a $_formatLabel'))),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
                color: AppTheme.coral.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.coral),
                const SizedBox(width: 10),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.coral, fontSize: 13))),
              ])),
          ],
          if (_resultFile != null) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                const Icon(Icons.check_circle, color: AppTheme.mint, size: 44),
                const SizedBox(height: 8),
                const Text('¡Archivo creado!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text(_resultFile!.path.split('/').last, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 14),
                SizedBox(height: 46, child: ElevatedButton.icon(
                  onPressed: _share, icon: const Icon(Icons.share),
                  label: const Text('Compartir'))),
              ])),
          ],
        ])));
  }
}

class _FormatTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FormatTile({required this.selected, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.pink100 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.pink400 : AppTheme.pink200),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppTheme.pink600 : AppTheme.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppTheme.pink700 : AppTheme.textPrimary,
          ))),
          if (selected) const Icon(Icons.check_circle, color: AppTheme.pink500, size: 20),
        ]),
      ),
    );
  }
}