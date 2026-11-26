import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/pdf_service.dart';
import '../core/theme.dart';
import 'pdf_reader_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _pdfService = PdfService();
  final _searchCtrl = TextEditingController();
  List<File> _files = [];
  List<File> _filtered = [];
  String _sortBy = 'date_desc';
  String? _typeFilter;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadFiles(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    final files = await _pdfService.listAppFiles(sortBy: _sortBy);
    setState(() { _files = files; _loading = false; });
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<File>.from(_files);
    if (_typeFilter != null) list = list.where((f) => f.path.toLowerCase().endsWith('.$_typeFilter')).toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((f) => f.path.split('/').last.toLowerCase().contains(q)).toList();
    setState(() => _filtered = list);
  }

  Future<void> _deleteFile(File file) async {
    final c = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Eliminar archivo'),
      content: Text('Seguro que deseas eliminar ${file.path.split('/').last}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.coral))),
      ]));
    if (c == true) { await _pdfService.deleteAppFile(file); _loadFiles(); }
  }

  Future<void> _shareFile(File file) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], title: 'Compartir'));
  }

  void _openPdf(File file) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PdfReaderScreen(filePath: file.path)));
  }

  IconData _iconFor(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'docx': return Icons.description;
      case 'xlsx': return Icons.table_chart;
      case 'pptx': return Icons.slideshow;
      default: return Icons.insert_drive_file;
    }
  }

  Color _colorFor(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'pdf': return AppTheme.bubblePinkDark;
      case 'docx': return AppTheme.bubbleBlueDark;
      case 'xlsx': return AppTheme.bubbleMintDark;
      case 'pptx': return AppTheme.bubbleCoralDark;
      default: return AppTheme.textSecondary;
    }
  }

  Color _bubbleFor(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'pdf': return AppTheme.bubblePink;
      case 'docx': return AppTheme.bubbleBlue;
      case 'xlsx': return AppTheme.bubbleMint;
      case 'pptx': return AppTheme.bubbleCoral;
      default: return AppTheme.bubbleLavender;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hoy ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Ayer';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📁 Mis Archivos'), centerTitle: true),
      body: Column(children: [
        _buildSearchBar(),
        _buildFilterRow(),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty ? _buildEmpty() : _buildFileList()),
      ]),);
  }

  Widget _buildSearchBar() {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(controller: _searchCtrl,
        decoration: InputDecoration(hintText: 'Buscar archivos...', prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear),
              onPressed: () { _searchCtrl.clear(); _applyFilters(); }) : null),
        onChanged: (_) => _applyFilters(),),);
  }

  Widget _buildFilterRow() {
    final types = [null, 'pdf', 'docx', 'xlsx', 'pptx', 'txt'];
    final labels = ['Todos', 'PDF', 'Word', 'Excel', 'PPT', 'TXT'];
    return SizedBox(height: 42, child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: types.length,
        itemBuilder: (ctx, i) {
          final s = _typeFilter == types[i];
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(selected: s,
              label: Text(labels[i], style: TextStyle(color: s ? Colors.white : AppTheme.textPrimary, fontSize: 12)),
              selectedColor: AppTheme.pink500, backgroundColor: AppTheme.white,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) { setState(() => _typeFilter = types[i]); _applyFilters(); },),);
        },),);
  }

  Widget _buildFileList() {
    return Column(children: [
      _buildSortChip(),
      Expanded(child: RefreshIndicator(onRefresh: _loadFiles,
        child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _filtered.length,
          itemBuilder: (ctx, i) => _buildFileCard(_filtered[i]),
        ),
      ),
    ),
    ]);
  }

  Widget _buildSortChip() {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(children: [
        Text('${_filtered.length} archivos', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const Spacer(),
        PopupMenuButton<String>(icon: const Icon(Icons.sort, size: 18, color: AppTheme.textSecondary),
          onSelected: (v) { setState(() => _sortBy = v); _loadFiles(); },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'date_desc', child: Text('Mas reciente')),
            const PopupMenuItem(value: 'date_asc', child: Text('Mas antiguo')),
            const PopupMenuItem(value: 'name_asc', child: Text('Nombre A-Z')),
            const PopupMenuItem(value: 'name_desc', child: Text('Nombre Z-A')),
            const PopupMenuItem(value: 'size', child: Text('Tamano')),
          ],
        ),
      ]),);
  }

  Widget _buildFileCard(File file) {
    final name = file.path.split('/').last;
    final ext = name.split('.').last.toUpperCase();
    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    final bubble = _bubbleFor(file.path);
    final dark = _colorFor(file.path);
    return Padding(padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(borderRadius: BorderRadius.circular(18),
        onTap: isPdf ? () => _openPdf(file) : () => _shareFile(file),
        onLongPress: () => _deleteFile(file),
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(18), boxShadow: AppTheme.softShadow),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: bubble, boxShadow: AppTheme.bubbleGlow(dark)),
              child: Icon(_iconFor(file.path), color: dark, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 3),
              Row(children: [
                Text(_formatDate(file.lastModifiedSync()),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: bubble, borderRadius: BorderRadius.circular(6)),
                    child: Text(ext, style: TextStyle(color: dark, fontSize: 10, fontWeight: FontWeight.w600))),
                const SizedBox(width: 6),
                Text(_formatSize(file.lengthSync()),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ]),
            ])),
            IconButton(icon: const Icon(Icons.share, size: 20), color: AppTheme.textMuted,
                onPressed: () => _shareFile(file), visualDensity: VisualDensity.compact),
          ]),),),);
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle,
          color: AppTheme.bubbleLavender, boxShadow: AppTheme.bubbleGlow(AppTheme.bubbleLavenderDark)),
        child: const Icon(Icons.folder_open, size: 44, color: AppTheme.bubbleLavenderDark)),
      const SizedBox(height: 16),
      const Text('Sin archivos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 4),
      const Text('Tus PDFs y documentos apareceran aqui', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]));
  }
}