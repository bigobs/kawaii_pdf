import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';

enum EditMode { watermark, protect, text }

class EditPdfScreen extends StatefulWidget {
  final EditMode mode;
  const EditPdfScreen({super.key, this.mode = EditMode.watermark});
  @override
  State<EditPdfScreen> createState() => _EditPdfScreenState();
}

class _EditPdfScreenState extends State<EditPdfScreen> {
  final _pdf = PdfService();
  final _wCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _tCtrl = TextEditingController();
  File? _file;
  bool _busy = false;
  File? _out;
  String? _err;
  bool _autoExtracting = false;

  // Watermark config
  double _wOpacity = 0.3;
  double _wFontSize = 48;
  String _wFontName = 'Helvetica';
  double _wAngle = -45;

  @override
  void dispose() {
    _wCtrl.dispose(); _pCtrl.dispose(); _tCtrl.dispose(); super.dispose();
  }

  EditMode get _m => widget.mode;

  Future<void> _pick() async {
    final r = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
    if (r != null && r.path != null) {
      setState(() {
        _file = File(r.path!); _out = null; _err = null;
      });
      if (_m == EditMode.text) {
        _autoExtractText();
      }
    }
  }

  Future<void> _autoExtractText() async {
    if (_file == null) return;
    setState(() { _autoExtracting = true; _err = null; });
    try {
      final t = await _pdf.extractText(_file!);
      setState(() { _tCtrl.text = t; _autoExtracting = false; });
    } catch (e) {
      setState(() { _err = 'Error al extraer: $e'; _autoExtracting = false; });
    }
  }

  Future<void> _run() async {
    if (_file == null) return;
    setState(() { _busy = true; _err = null; });
    try {
      File result;
      if (_m == EditMode.protect) {
        final p = _pCtrl.text;
        if (p.isEmpty) { _fail('Ingresa una contrasena'); return; }
        result = await _pdf.protectPdf(_file!, p);
      } else if (_m == EditMode.text) {
        final t = _tCtrl.text;
        if (t.isEmpty) { _fail('Edita el texto y aplica los cambios'); return; }
        result = await _pdf.modifyPdfText(sourceFile: _file!, newText: t);
      } else {
        final t = _wCtrl.text;
        if (t.isEmpty) { _fail('Ingresa texto de marca de agua'); return; }
        result = await _pdf.addWatermark(
          file: _file!,
          watermarkText: t,
          opacity: _wOpacity,
          fontSize: _wFontSize,
          fontName: _wFontName,
          angle: _wAngle,
        );
      }
      setState(() { _out = result; _busy = false; });
    } catch (e) {
      setState(() { _err = 'Error: $e'; _busy = false; });
    }
  }

  void _fail(String msg) => setState(() { _err = msg; _busy = false; });

  Future<void> _share() async {
    if (_out == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(_out!.path)]));
  }

  String get _title => switch (_m) {
    EditMode.watermark => 'Marca de agua',
    EditMode.protect => 'Proteger PDF',
    EditMode.text => 'Modificar texto',
  };

  String get _ok => switch (_m) {
    EditMode.watermark => 'Marca aplicada!',
    EditMode.protect => 'PDF protegido!',
    EditMode.text => 'Texto modificado!',
  };

  @override
  Widget build(BuildContext context) {
    final name = _file?.path.split('/').last ?? 'Ningun archivo';
    final c = _m == EditMode.protect
        ? AppTheme.coral
        : _m == EditMode.text ? AppTheme.pink500 : AppTheme.pink600;
    final icon = _m == EditMode.protect ? Icons.lock
        : _m == EditMode.text ? Icons.save : Icons.edit;
    final label = _m == EditMode.protect ? 'Proteger PDF'
        : _m == EditMode.text ? 'Guardar cambios' : 'Aplicar marca';

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFFEA4335), size: 40),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
              ElevatedButton(onPressed: _pick, child: const Text('Seleccionar')),
            ])),
          ),
          const SizedBox(height: 24),
          if (_file != null) ...[
            if (_m == EditMode.protect) ...[
              const Text('Proteger con contrasena',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('El PDF sera cifrado con AES-256.'),
              const SizedBox(height: 12),
              TextField(
                controller: _pCtrl, obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Contrasena', border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock)),
              ),
            ],
            if (_m == EditMode.watermark) ...[
              const Text('💧 Marca de agua',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _wCtrl,
                decoration: const InputDecoration(
                    labelText: 'Texto de la marca',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.text_fields),
                    hintText: 'CONFIDENCIAL'),
              ),
              const SizedBox(height: 16),
              const Text('Opacidad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Row(children: [
                Expanded(
                  child: Slider(
                    value: _wOpacity,
                    min: 0.1, max: 1.0, divisions: 9,
                    activeColor: AppTheme.pink500,
                    label: _wOpacity.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _wOpacity = v),
                  ),
                ),
                SizedBox(width: 40, child: Text(_wOpacity.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
              ]),
              const SizedBox(height: 8),
              const Text('Tamaño de fuente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Row(children: [
                Expanded(
                  child: Slider(
                    value: _wFontSize,
                    min: 18, max: 120, divisions: 17,
                    activeColor: AppTheme.pink500,
                    label: _wFontSize.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _wFontSize = v),
                  ),
                ),
                SizedBox(width: 40, child: Text(_wFontSize.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
              ]),
              const SizedBox(height: 8),
              const Text('Ángulo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Row(children: [
                Expanded(
                  child: Slider(
                    value: _wAngle,
                    min: -90, max: 0, divisions: 9,
                    activeColor: AppTheme.coral,
                    label: _wAngle.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _wAngle = v),
                  ),
                ),
                SizedBox(width: 40, child: Text('${_wAngle.toStringAsFixed(0)}°',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
              ]),
              const SizedBox(height: 12),
              const Text('Fuente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _wFontName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Helvetica', child: Text('Helvetica (sans-serif)')),
                  DropdownMenuItem(value: 'Courier', child: Text('Courier (monoespaciada)')),
                  DropdownMenuItem(value: 'Times', child: Text('Times (serif)')),
                ],
                onChanged: (v) { if (v != null) setState(() => _wFontName = v); },
              ),
            ],
            if (_m == EditMode.text) ...[
              const Row(children: [
                Expanded(child: Text('Modificar texto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ]),
              const SizedBox(height: 8),
              if (_autoExtracting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(children: [
                    SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Extrayendo texto del PDF...',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ]),
                )
              else ...[
                const Text('El texto se extrae automáticamente al seleccionar el PDF. Edítalo y aplica los cambios.'),
                const SizedBox(height: 12),
                TextField(controller: _tCtrl, maxLines: 14,
                  decoration: const InputDecoration(
                      labelText: 'Texto editable', border: OutlineInputBorder(),
                      alignLabelWithHint: true)),
              ],
            ],
            const SizedBox(height: 16),
            SizedBox(height: 48, child: ElevatedButton.icon(
              onPressed: _busy ? null : _run,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                  backgroundColor: c, foregroundColor: Colors.white),
            )),
          ],
          if (_err != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(_err!,
                  style: const TextStyle(color: AppTheme.coral)),
            ),
          ],
          if (_out != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.pink600, size: 48),
                const SizedBox(height: 8),
                Text(_ok,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.pink600)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir')),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

