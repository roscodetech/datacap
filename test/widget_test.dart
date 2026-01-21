import 'package:flutter_test/flutter_test.dart';

import 'package:datacap/main.dart';

void main() {
  testWidgets('DataCap app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DataCapApp());

    // Verify app title is present
    expect(find.text('DataCap'), findsOneWidget);
    expect(find.text('ML Data Collection'), findsOneWidget);
  });
}
