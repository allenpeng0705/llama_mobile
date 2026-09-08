import 'package:flutter_test/flutter_test.dart';
import 'package:llama_mobile_flutter_sdk_example/main.dart';

void main() {
  testWidgets('v2 example renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('LlamaEngine v2 — Flutter'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });
}
