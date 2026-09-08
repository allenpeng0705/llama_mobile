// Smoke test for the llama_mobile v2 Flutter example: the app shell renders
// with the four capability tabs. No model is touched (pure widget layer).
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_sdk_example/main.dart';

void main() {
  testWidgets('v2 example renders Chat/Embed/Vision/Model tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LlamaEngine v2 — Flutter'), findsOneWidget);
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Embed'), findsWidgets);
    expect(find.text('Vision'), findsWidgets);
    expect(find.text('Model'), findsWidgets);

    // Switch tabs to force each view to build without exceptions.
    await tester.tap(find.text('Embed'));
    await tester.pumpAndSettle();
    expect(find.text('Embeddings (opens its own engine with embedding = true)'),
        findsOneWidget);

    await tester.tap(find.text('Vision'));
    await tester.pumpAndSettle();
    expect(find.text('Ask about an image'), findsOneWidget);

    await tester.tap(find.text('Model'));
    await tester.pumpAndSettle();
    expect(find.text('Introspection (modelInfo + tokenize/detokenize)'),
        findsOneWidget);
  });
}
