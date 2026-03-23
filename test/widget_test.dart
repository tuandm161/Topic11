import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tet_budget_app/views/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads Tet budget home screen and opens chart screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TetBudgetApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Săn Sale Tết'), findsOneWidget);
    expect(find.text('Hạng mục mua sắm'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.insights_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Báo cáo chi tiêu'), findsOneWidget);
    expect(find.text('Phân bổ chi tiêu theo hạng mục'), findsOneWidget);
  });
}
