import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popcorn_diary/main.dart';

void main() {
  testWidgets('App boots and shows the Diary screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PopcornDiaryApp()));
    await tester.pumpAndSettle();

    expect(find.text('Movie Journal'), findsOneWidget);
  });
}
