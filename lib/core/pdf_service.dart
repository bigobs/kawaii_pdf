import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect, Offset;

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

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

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------

  Future<int> getPageCount(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final count = document.pages.count;
    document.dispose();
    return count;
  }

  Future<File> _saveToFile(List<int> bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\-.]'), '_').trim();
  }
}
