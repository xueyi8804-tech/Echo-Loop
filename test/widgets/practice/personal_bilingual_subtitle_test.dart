import 'package:echo_loop/l10n/app_localizations.dart';
import 'package:echo_loop/widgets/practice/practice_normal_mode_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('个人版打开字幕同时显示中英文，隐藏时都不可见', (tester) async {
    const english = 'This is a lesson.';
    Widget page(bool revealed) => createTestApp(
      Scaffold(body: Builder(builder: (context) => PracticeNormalModeView(
        l10n: AppLocalizations.of(context)!,
        theme: Theme.of(context),
        isTextRevealed: revealed,
        sentenceText: english,
        onPeekToggle: () {},
        onCantUnderstand: () {},
        onToggleMark: () {},
      ))),
      overrides: [
        practiceChineseSubtitleProvider(english).overrideWith((ref) async => '这是一节课。'),
      ],
    );
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(find.text(english), findsOneWidget);
    expect(find.text('这是一节课。'), findsOneWidget);
    await tester.pumpWidget(page(false));
    await tester.pumpAndSettle();
    expect(find.text(english), findsNothing);
    expect(find.text('这是一节课。'), findsNothing);
  });
}
