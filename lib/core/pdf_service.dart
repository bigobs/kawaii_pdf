import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect, Offset;

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

import 'office_templates.dart';

/// Servicio central para operaciones de manipulacion de PDFs.
class PdfService {
  // ---------------------------------------------------------------------------
  // Crear
  // ---------------------------------------------------------------------------

  Future<File> createPdf({
    required String title,
    required String content,
    String? author,
    bool isBold = false,
    bool isItalic = false,
    double fontSize = 12,
    String fontFamily = 'Helvetica',
  }) async {
    final document = PdfDocument();
    document.documentInformation.title = title;
    document.documentInformation.author = author ?? 'bigobs';
    document.documentInformation.creator = 'bigobs';

    final page = document.pages.add();
    final graphics = page.graphics;
    final size = page.getClientSize();

    final pdfFontFamily = _fontFamilyFromName(fontFamily);
    PdfFontStyle style = PdfFontStyle.regular;
    if (isBold) style = PdfFontStyle.bold;
    if (isItalic) style = PdfFontStyle.italic;

    graphics.drawString(
      title,
      PdfStandardFont(pdfFontFamily, 24, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(40, 40, size.width - 80, 40),
    );

    graphics.drawLine(
      PdfPens.gray,
      Offset(40, 90),
      Offset(size.width - 40, 90),
    );

    final bodyFont = PdfStandardFont(pdfFontFamily, fontSize, style: style);
    graphics.drawString(
      content,
      bodyFont,
      bounds: Rect.fromLTWH(40, 110, size.width - 80, size.height - 150),
      format: PdfStringFormat(lineSpacing: 6),
    );

    graphics.drawString(
      'Creado con kawaii pdf — ${DateTime.now().toString().substring(0, 19)}',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      bounds: Rect.fromLTWH(40, size.height - 40, size.width - 80, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final bytes = await document.save();
    document.dispose();
    return _saveToFile(bytes, '${_sanitizeFileName(title)}.pdf');
  }

  // ---------------------------------------------------------------------------
  // Unir PDFs
  // ---------------------------------------------------------------------------

  Future<File> mergePdfs({
    required List<File> files,
    String? outputName,
  }) async {
    final mergedDocument = PdfDocument();

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final sourceDocument = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < sourceDocument.pages.count; i++) {
        final template = sourceDocument.pages[i].createTemplate();
        final newPage = mergedDocument.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          newPage.getClientSize(),
        );
      }
      sourceDocument.dispose();
    }

    final mergedBytes = await mergedDocument.save();
    mergedDocument.dispose();
    return _saveToFile(
      mergedBytes,
      outputName ?? 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Dividir
  // ---------------------------------------------------------------------------

  Future<List<File>> splitPdfAllPages(File file) async {
    final bytes = await file.readAsBytes();
    final sourceDocument = PdfDocument(inputBytes: bytes);
    final files = <File>[];

    for (int i = 0; i < sourceDocument.pages.count; i++) {
      final newDocument = PdfDocument();
      final template = sourceDocument.pages[i].createTemplate();
      final newPage = newDocument.pages.add();
      newPage.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        newPage.getClientSize(),
      );

      final pageBytes = await newDocument.save();
      files.add(
        await _saveToFile(
          pageBytes,
          'page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      );
      newDocument.dispose();
    }

    sourceDocument.dispose();
    return files;
  }

  Future<File> splitPdfRange({
    required File file,
    required int startPage,
    required int endPage,
  }) async {
    final bytes = await file.readAsBytes();
    final sourceDocument = PdfDocument(inputBytes: bytes);
    final newDocument = PdfDocument();

    for (
      int i = startPage;
      i <= endPage && i < sourceDocument.pages.count;
      i++
    ) {
      final template = sourceDocument.pages[i].createTemplate();
      final newPage = newDocument.pages.add();
      newPage.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        newPage.getClientSize(),
      );
    }

    final resultBytes = await newDocument.save();
    newDocument.dispose();
    sourceDocument.dispose();
    return _saveToFile(
      resultBytes,
      'split_${startPage + 1}-${endPage + 1}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Seguridad / Desbloquear
  // ---------------------------------------------------------------------------

  Future<File?> unlockPdf(File file, String password) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes, password: password);

      final newDocument = PdfDocument();
      for (int i = 0; i < document.pages.count; i++) {
        final template = document.pages[i].createTemplate();
        final newPage = newDocument.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          newPage.getClientSize(),
        );
      }

      final unlockedBytes = await newDocument.save();
      newDocument.dispose();
      document.dispose();
      return await _saveToFile(
        unlockedBytes,
        'unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> isPdfEncrypted(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final hasPassword =
          document.security.userPassword.isNotEmpty ||
          document.security.ownerPassword.isNotEmpty;
      document.dispose();
      return hasPassword;
    } catch (e) {
      return true;
    }
  }

  Future<File> protectPdf(File file, String password) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    document.security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    document.security.userPassword = password;
    document.security.ownerPassword = password;

    final resultBytes = await document.save();
    document.dispose();
    return _saveToFile(
      resultBytes,
      'protected_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Divide el PDF desde [pageIndex] (0-based) hasta la ultima pagina.
  Future<File> splitPdfFromPage(File file, int pageIndex) async {
    final bytes = await file.readAsBytes();
    final sourceDocument = PdfDocument(inputBytes: bytes);
    final newDocument = PdfDocument();
    final total = sourceDocument.pages.count;

    for (int i = pageIndex; i < total; i++) {
      final template = sourceDocument.pages[i].createTemplate();
      final page = newDocument.pages.add();
      page.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        page.getClientSize(),
      );
    }

    sourceDocument.dispose();
    final resultBytes = await newDocument.save();
    newDocument.dispose();
    return _saveToFile(resultBytes, 'from_page_${pageIndex + 1}_to_$total.pdf');
  }

  // ---------------------------------------------------------------------------
  // Marca de agua
  // ---------------------------------------------------------------------------

  Future<File> addWatermark({
    required File file,
    required String watermarkText,
    String? outputName,
    double opacity = 0.3,
    double fontSize = 48,
    String fontName = 'Helvetica',
    double angle = -45,
  }) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    final fontFamily = _fontFamilyFromName(fontName);
    final font = PdfStandardFont(fontFamily, fontSize);

    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final graphics = page.graphics;
      final pageSize = page.getClientSize();

      final textSize = font.measureString(watermarkText);
      final state = graphics.save();

      graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
      graphics.rotateTransform(angle);

      final alpha = (opacity * 255).toInt().clamp(0, 255);

      graphics.drawString(
        watermarkText,
        font,
        brush: PdfSolidBrush(PdfColor(alpha, alpha, alpha)),
        bounds: Rect.fromLTWH(
          -textSize.width / 2,
          -textSize.height / 2,
          textSize.width,
          textSize.height,
        ),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        ),
      );

      graphics.restore(state);
    }

    final resultBytes = await document.save();
    document.dispose();
    return _saveToFile(
      resultBytes,
      outputName ?? 'watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  PdfFontFamily _fontFamilyFromName(String name) => switch (name) {
    'Courier' => PdfFontFamily.courier,
    'Times' => PdfFontFamily.timesRoman,
    _ => PdfFontFamily.helvetica,
  };

  // ---------------------------------------------------------------------------
  // Modificar texto
  // ---------------------------------------------------------------------------

  /// Extrae todo el texto del PDF.
  Future<String> extractText(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final buffer = StringBuffer();
    final extractor = PdfTextExtractor(document);

    for (int i = 0; i < document.pages.count; i++) {
      if (i > 0) buffer.writeln('\n--- Pagina ${i + 1} ---\n');
      final text = extractor.extractText(startPageIndex: i);
      buffer.write(text);
    }

    document.dispose();
    return buffer.toString();
  }

  /// Crea un PDF nuevo con el texto editado, tapando el original.
  Future<File> modifyPdfText({
    required File sourceFile,
    required String newText,
  }) async {
    final bytes = await sourceFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final pageCount = document.pages.count;
    final newDocument = PdfDocument();

    for (int i = 0; i < pageCount; i++) {
      final sourcePage = document.pages[i];
      final pageSize = sourcePage.getClientSize();

      // Copia pagina original como fondo
      final template = sourcePage.createTemplate();
      final newPage = newDocument.pages.add();
      newPage.graphics.drawPdfTemplate(template, Offset.zero, pageSize);

      // Tapa texto original con rectangulos blancos
      final extractor = PdfTextExtractor(document);
      final textLines = extractor.extractTextLines(startPageIndex: i);
      for (final line in textLines) {
        for (final word in line.wordCollection) {
          newPage.graphics.drawRectangle(
            brush: PdfSolidBrush(PdfColor(255, 255, 255)),
            bounds: Rect.fromLTWH(
              word.bounds.left - 2,
              word.bounds.top - 1,
              word.bounds.width + 4,
              word.bounds.height + 2,
            ),
          );
        }
      }
    }

    // Dibuja nuevo texto en primera pagina
    final firstPage = newDocument.pages[0];
    final pageSize = firstPage.getClientSize();
    const margin = 40.0;
    firstPage.graphics.drawString(
      newText,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        margin,
        margin,
        pageSize.width - margin * 2,
        pageSize.height - margin * 2,
      ),
      format: PdfStringFormat(lineSpacing: 6),
    );

    document.dispose();
    final resultBytes = await newDocument.save();
    newDocument.dispose();
    return _saveToFile(
      resultBytes,
      'edited_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Import Office (DOCX, XLSX)
  // ---------------------------------------------------------------------------

  /// Extrae texto de un archivo .docx.
  Future<String> extractTextFromDocx(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? docXml;
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        docXml = f;
        break;
      }
    }
    if (docXml == null) throw Exception('No se encontró word/document.xml');

    final xmlStr = utf8.decode(docXml.content as List<int>);
    final doc = XmlDocument.parse(xmlStr);
    final texts = <String>[];
    for (final e in doc.descendants.whereType<XmlElement>()) {
      if (e.name.local == 't' &&
          (e.name.namespaceUri?.contains('wordml') ?? false)) {
        texts.add(e.innerText);
      }
    }
    return texts.join('');
  }

  /// Extrae texto de un archivo .xlsx.
  Future<String> extractTextFromXlsx(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1) Shared strings
    final sharedStrings = <String>[];
    ArchiveFile? sharedXml;
    for (final f in archive.files) {
      if (f.name == 'xl/sharedStrings.xml') {
        sharedXml = f;
        break;
      }
    }
    if (sharedXml != null) {
      final ssDoc = XmlDocument.parse(
        utf8.decode(sharedXml.content as List<int>),
      );
      for (final si in ssDoc.descendants.whereType<XmlElement>()) {
        if (si.name.local == 'si') {
          final t = si.descendants
              .whereType<XmlElement>()
              .where((e) => e.name.local == 't')
              .map((e) => e.innerText)
              .join('');
          sharedStrings.add(t);
        }
      }
    }

    // 2) Sheet cells
    final buffer = StringBuffer();
    for (final f in archive.files) {
      if (!f.name.startsWith('xl/worksheets/sheet') ||
          !f.name.endsWith('.xml')) {
        continue;
      }

      final sheetDoc = XmlDocument.parse(
        utf8.decode(f.content as List<int>),
      );
      final rows = sheetDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'row');
      for (final row in rows) {
        final cells = row.children.whereType<XmlElement>();
        final rowTexts = <String>[];
        for (final cell in cells) {
          final v = cell.descendants
              .whereType<XmlElement>()
              .where((e) => e.name.local == 'v')
              .map((e) => e.innerText)
              .firstOrNull;
          final t = cell.getAttribute('t');
          if (v != null) {
            if (t == 's') {
              final idx = int.tryParse(v);
              if (idx != null && idx < sharedStrings.length) {
                rowTexts.add(sharedStrings[idx]);
              } else {
                rowTexts.add(v);
              }
            } else {
              rowTexts.add(v);
            }
          }
        }
        if (rowTexts.isNotEmpty) buffer.writeln(rowTexts.join('\t'));
      }
    }

    return buffer.toString().trimRight();
  }

  /// Extrae texto de un archivo .pptx.
  Future<String> extractTextFromPptx(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final slideNames = <String>[];
    for (final f in archive.files) {
      final n = f.name;
      if (n.startsWith('ppt/slides/slide') && n.endsWith('.xml')) {
        slideNames.add(n);
      }
    }
    slideNames.sort();

    final buffer = StringBuffer();
    int slideNum = 0;
    for (final name in slideNames) {
      slideNum++;
      final archiveFile = archive.files.firstWhere((f) => f.name == name);
      final xmlStr = utf8.decode(archiveFile.content as List<int>);
      final doc = XmlDocument.parse(xmlStr);
      final texts = <String>[];
      for (final e in doc.descendants.whereType<XmlElement>()) {
        if (e.name.local == 't' &&
            (e.name.namespaceUri?.contains('drawingml') ?? false)) {
          texts.add(e.innerText);
        }
      }
      if (texts.isNotEmpty) {
        if (slideNum > 1) buffer.writeln();
        buffer.writeln('--- Diapositiva $slideNum ---');
        buffer.write(texts.join(' '));
      }
    }
    return buffer.toString().trimRight();
  }

  // ---------------------------------------------------------------------------
  // Export: PDF → Office / TXT
  // ---------------------------------------------------------------------------

  /// Exporta el texto del PDF a un .docx mínimo.
  Future<File> exportPdfToDocx(File pdfFile, {String? baseName}) async {
    final text = await extractText(pdfFile);
    final name = baseName ?? 'export_${DateTime.now().millisecondsSinceEpoch}';
    final encoder = ZipEncoder();
    final archive = Archive();
    _addString(archive, '[Content_Types].xml', OfficeTemplates.docxCt);
    _addString(archive, '_rels/.rels', OfficeTemplates.docxRels);
    _addString(archive, 'word/_rels/document.xml.rels', OfficeTemplates.docxDocRels);
    _addString(archive, 'word/document.xml', OfficeTemplates.docxDoc(escapeXml(text)));
    final zipBytes = encoder.encode(archive);
    return _saveToFile(zipBytes, '${_sanitizeFileName(name)}.docx');
  }

  /// Exporta el texto del PDF a un .xlsx mínimo.
  Future<File> exportPdfToXlsx(File pdfFile, {String? baseName}) async {
    final text = await extractText(pdfFile);
    final name = baseName ?? 'export_${DateTime.now().millisecondsSinceEpoch}';
    final lines = _sanitizeSheetText(text.split('\n'));
    final encoder = ZipEncoder();
    final archive = Archive();
    _addString(archive, '[Content_Types].xml', OfficeTemplates.xlsxCt);
    _addString(archive, '_rels/.rels', OfficeTemplates.xlsxRels);
    _addString(archive, 'xl/_rels/workbook.xml.rels', OfficeTemplates.xlsxWbRels);
    _addString(archive, 'xl/workbook.xml', OfficeTemplates.xlsxWb);
    _addString(archive, 'xl/worksheets/sheet1.xml', OfficeTemplates.xlsxSheet(lines, _colName));
    _addString(archive, 'xl/sharedStrings.xml', OfficeTemplates.xlsxSs(lines));
    final zipBytes = encoder.encode(archive);
    return _saveToFile(zipBytes, '${_sanitizeFileName(name)}.xlsx');
  }

  /// Exporta el texto del PDF a un archivo .txt.
  Future<File> exportPdfToTxt(File pdfFile, {String? baseName}) async {
    final text = await extractText(pdfFile);
    final name = baseName ?? 'export_${DateTime.now().millisecondsSinceEpoch}';
    return _saveToFile(utf8.encode(text), '${_sanitizeFileName(name)}.txt');
  }

  /// Exporta el PDF a .pptx (una diapositiva por página).
  Future<File> exportPdfToPptx(File pdfFile, {String? baseName}) async {
    final pages = await _extractTextPerPage(pdfFile);
    final name = baseName ?? 'export_${DateTime.now().millisecondsSinceEpoch}';
    final encoder = ZipEncoder();
    final archive = Archive();
    _addString(archive, '[Content_Types].xml', OfficeTemplates.pptxCt);
    _addString(archive, '_rels/.rels', OfficeTemplates.pptxRels);
    _addString(archive, 'ppt/_rels/presentation.xml.rels', OfficeTemplates.pptxPresRels);
    _addString(archive, 'ppt/presentation.xml', OfficeTemplates.pptxPres);
    _addString(archive, 'ppt/presProps.xml', OfficeTemplates.pptxPresPr);
    _addString(archive, 'ppt/tableStyles.xml', OfficeTemplates.pptxTblSt);
    _addString(archive, 'ppt/slideMasters/slideMaster1.xml', OfficeTemplates.pptxSM);
    _addString(archive, 'ppt/slideMasters/_rels/slideMaster1.xml.rels', OfficeTemplates.pptxSMRels);
    _addString(archive, 'ppt/slideLayouts/slideLayout1.xml', OfficeTemplates.pptxLayout);
    _addString(archive, 'ppt/slideLayouts/_rels/slideLayout1.xml.rels', OfficeTemplates.pptxLayoutRels);
    _addString(archive, 'ppt/theme/theme1.xml', OfficeTemplates.pptxTheme);
    for (int i = 0; i < pages.length; i++) {
      _addString(archive, 'ppt/slides/slide${i + 1}.xml',
          OfficeTemplates.pptxSlide(i + 1, pages[i]));
      _addString(archive, 'ppt/slides/_rels/slide${i + 1}.xml.rels', OfficeTemplates.pptxSlideRels);
    }
    final zipBytes = encoder.encode(archive);
    return _saveToFile(zipBytes, '${_sanitizeFileName(name)}.pptx');
  }

  /// Extrae texto página por página.
  Future<List<String>> _extractTextPerPage(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final pages = <String>[];
    for (int i = 0; i < document.pages.count; i++) {
      pages.add(extractor.extractText(startPageIndex: i));
    }
    document.dispose();
    return pages;
  }

  void _addString(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  /// Escapa caracteres XML.
  static String escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static List<String> _sanitizeSheetText(List<String> lines) {
    return lines.map((l) {
      return l.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    }).toList();
  }

  static String _colName(int i) {
    final buf = StringBuffer();
    int n = i;
    while (n >= 0) {
      buf.writeCharCode(65 + (n % 26));
      n = n ~/ 26 - 1;
    }
    return buf.toString().split('').reversed.join();
  }

  Future<int> getPageCount(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final count = document.pages.count;
    document.dispose();
    return count;
  }

  /// Directorio unificado de la app para todos los archivos generados.
  Future<Directory> getAppDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/kawaii_pdf');
    if (!await appDir.exists()) await appDir.create(recursive: true);
    return appDir;
  }

  Future<File> _saveToFile(List<int> bytes, String fileName) async {
    final appDir = await getAppDirectory();
    final file = File('${appDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }


  // ---------------------------------------------------------------------------
  // Escanear — crear PDF desde imagen (cámara)
  // ---------------------------------------------------------------------------

  Future<File> createPdfFromImage(File imageFile, {String? title}) async {
    final bytes = await imageFile.readAsBytes();
    final image = PdfBitmap(bytes);

    final document = PdfDocument();
    document.documentInformation.title = title ?? 'Documento escaneado';
    document.documentInformation.creator = 'kawaii pdf';

    final page = document.pages.add();
    final size = page.getClientSize();

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final scale = (size.width / imgW).clamp(0.0, (size.height / imgH));
    final w = imgW * scale;
    final h = imgH * scale;
    final x = (size.width - w) / 2;
    final y = (size.height - h) / 2;

    page.graphics.drawImage(image, Rect.fromLTWH(x, y, w, h));

    final out = await _saveToFile(
      await document.save(),
      'scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    document.dispose();
    return out;
  }

  // ---------------------------------------------------------------------------
  // Gestor de archivos
  // ---------------------------------------------------------------------------

  Future<List<File>> listAppFiles({String? filter, String? sortBy}) async {
    final appDir = await getAppDirectory();
    final all = await appDir.list().toList();
    var files = all.whereType<File>().toList();

    if (filter != null && filter.isNotEmpty) {
      final q = filter.toLowerCase();
      files = files.where((f) {
        final name = f.path.split('/').last.toLowerCase();
        return name.contains(q);
      }).toList();
    }

    sortBy ??= 'date_desc';
    switch (sortBy) {
      case 'name_asc':
        files.sort((a, b) => a.path.compareTo(b.path));
      case 'name_desc':
        files.sort((a, b) => b.path.compareTo(a.path));
      case 'date_asc':
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      case 'size':
        files.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
      default:
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }

    return files;
  }

  Future<void> deleteAppFile(File file) async {
    if (await file.exists()) await file.delete();
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\-.]'), '_').trim();
  }
}
