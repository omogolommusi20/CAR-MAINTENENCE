import 'package:flutter_test/flutter_test.dart';
import 'package:carmaintenance/auth_screen.dart';

void main() {
  testWidgets('Auth screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const CarMaintenanceApp());
  });
}
