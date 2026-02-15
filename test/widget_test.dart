import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math/managers/profile_manager.dart';
import 'package:math/main.dart';

void main() {
  testWidgets('App shows main menu', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ProfileManager().initialize();
    await tester.pumpWidget(const MathApp());
    await tester.pumpAndSettle();

    expect(find.text('Math Genius! 🌟'), findsOneWidget);
    expect(find.text('Hello, Default!'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });
}
