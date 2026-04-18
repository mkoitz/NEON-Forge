import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:neon_forge/main.dart';

void main() {
  testWidgets('shows forge board on launch', (WidgetTester tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    await tester.pumpWidget(const NeonForgeApp());
    await tester.pumpAndSettle();

    expect(find.text('NEON FORGE'), findsOneWidget);
    expect(find.text('CURRENT GOAL'), findsOneWidget);
    expect(find.text('PROGRAM'), findsWidgets);
    expect(find.textContaining('Goal: forge Program'), findsOneWidget);
  });
}
