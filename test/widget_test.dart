import 'package:flutter_test/flutter_test.dart';

import 'package:kawaii_pdf/main.dart';

void main() {
  testWidgets('App muestra pantalla principal', (WidgetTester tester) async {
    await tester.pumpWidget(const KawaiiPdfApp());

    // Verifica que la app muestra el titulo
    expect(find.text('kawaii pdf'), findsOneWidget);
    expect(find.text('✨ Herramientas PDF'), findsOneWidget);

    // Verifica que al menos las primeras herramientas estan visibles
    expect(find.text('Crear PDF'), findsOneWidget);
    expect(find.text('Unir PDFs'), findsOneWidget);
  });
}

