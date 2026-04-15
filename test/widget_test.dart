import 'package:flutter_test/flutter_test.dart';

import 'package:neon_forge/main.dart';

void main() {
  testWidgets('shows NEON Forge title', (WidgetTester tester) async {
    await tester.pumpWidget(const NeonForgeApp());

    expect(find.text('NEON Forge'), findsOneWidget);
    expect(find.text('Discovered Library'), findsOneWidget);
  });
}
