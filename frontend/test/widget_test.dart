import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snaqquest_frontend/app.dart';

void main() {
  testWidgets('app shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SnaqQuestApp(firebaseReady: false));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
