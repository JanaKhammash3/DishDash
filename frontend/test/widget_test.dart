import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart'; // adjust this if the path is different

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(MyApp());

    // Check initial counter value
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Check if counter incremented
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
