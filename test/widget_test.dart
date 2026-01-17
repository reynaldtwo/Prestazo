import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/main.dart';

void main() {
  testWidgets('PrestamosApp renders correctly', (WidgetTester tester) async {
    // Construir la aplicación dentro de un ProviderScope para Riverpod.
    await tester.pumpWidget(const ProviderScope(child: PrestamosApp()));

    // Verificar que el widget principal de la aplicación esté presente.
    expect(find.byType(PrestamosApp), findsOneWidget);
  });
}
