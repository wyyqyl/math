import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Icon, Icons, Text;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math/main.dart';
import 'package:math/managers/profile_manager.dart';
import 'package:math/models/question_model.dart';
import 'package:math/screens/widgets/multiplication_array.dart';
import 'package:math/screens/widgets/study_layout.dart';

Future<void> openApp(
  WidgetTester tester, {
  Size viewport = const Size(390, 700),
  Map<String, Object> prefs = const {},
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(viewport);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  SharedPreferences.setMockInitialValues({
    'profile_list': ['Default'],
    'active_profile': 'Default',
    'profile_Default_soundEnabled': false,
    ...prefs,
  });
  await ProfileManager().initialize();
  await tester.pumpWidget(const MathApp());
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Explores 12 × 12 and practices the selected table', (
    tester,
  ) async {
    await openApp(tester);
    expect(find.text('Hello, Default!'), findsOneWidget);
    expect(find.text('Explore times tables').hitTestable(), findsOneWidget);

    await tapVisible(tester, 'Explore times tables');
    await tapVisible(tester, '12');
    await tapVisible(tester, '× 12');
    expect(find.text('12 × 12 = 144'), findsOneWidget);
    final array = tester.widget<MultiplicationArray>(
      find.byType(MultiplicationArray),
    );
    expect(array.rows, 12);
    expect(array.columns, 12);

    await tapVisible(tester, 'Practice the 12 times table');
    final question = tester
        .widget<AnswerChoices>(find.byType(AnswerChoices))
        .question;
    expect(question.num1, 12);
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();

    await tapVisible(tester, 'Show a hint');
    expect(find.byType(MultiplicationArray), findsOneWidget);
    final wrong = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );
    await tapVisible(tester, '$wrong');
    expect(find.text('Let’s work it out'), findsOneWidget);
    expect(find.text(question.equation), findsOneWidget);
  });

  testWidgets('Returns a missed practice fact after two other questions', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, 'Mixed practice');
    Question current() =>
        tester.widget<AnswerChoices>(find.byType(AnswerChoices)).question;
    final missed = current();
    final wrong = missed.options.firstWhere(
      (option) => option != missed.correctAnswer,
    );
    await tapVisible(tester, '$wrong');
    await tapVisible(tester, 'Next question');
    for (var attempt = 0; attempt < 2; attempt++) {
      final question = current();
      expect(question.questionKey, isNot(missed.questionKey));
      await tester.tap(find.text('${question.correctAnswer}'));
      await tester.pump();
      expect(find.text('Correct!'), findsOneWidget);
      expect(find.byType(AnswerChoices), findsNothing);
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.text('Correct!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Correct!'), findsNothing);
    }
    expect(current().questionKey, missed.questionKey);
  });

  testWidgets('Finishing practice cancels advancement after a correct answer', (
    tester,
  ) async {
    await openApp(tester, viewport: const Size(1024, 768));
    await tapVisible(tester, 'Mixed practice');
    final question = tester
        .widget<AnswerChoices>(find.byType(AnswerChoices))
        .question;

    await tester.tap(find.text('${question.correctAnswer}'));
    await tester.pump();
    final feedback = tester.widget<Text>(find.text('Correct!'));
    final result = tester.widget<Text>(find.text(question.equation));
    expect(feedback.style?.fontSize, 64);
    expect(result.style?.fontSize, 58);
    expect(result.style?.color, studyGreen);
    await tester.tap(find.text('Finish'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Practice complete'), findsOneWidget);
    expect(find.byType(AnswerChoices), findsNothing);
  });

  testWidgets('Tablet portrait practice brings the keypad within reach', (
    tester,
  ) async {
    const viewport = Size(834, 1194);
    await openApp(
      tester,
      viewport: viewport,
      prefs: {'profile_Default_advancedMode': true},
    );
    await tapVisible(tester, 'Mixed practice');

    final equation = tester.getRect(find.byType(Equation));
    final bottomDigit = find.text('0');
    final digit = tester.getRect(bottomDigit);
    expect(digit.top, greaterThan(equation.bottom));
    expect(digit.bottom, greaterThan(viewport.height * 0.85));
    expect(digit.bottom, lessThan(viewport.height));
    for (final icon in [Icons.backspace_rounded, Icons.check_rounded]) {
      final control = find.byIcon(icon).hitTestable();
      expect(control, findsOneWidget);
      expect(tester.widget<Icon>(control).size, greaterThan(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Quiz records one answer per question and opens a missed-fact review',
    (tester) async {
      const viewport = Size(1024, 768);
      await openApp(tester, viewport: viewport);
      await tester.tap(find.bySemanticsLabel('Multiplication quiz'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Start without a timer');

      final equation = tester.getRect(find.byType(Equation));
      final answers = tester.getRect(find.byType(AnswerChoices));
      expect(equation.right, lessThan(answers.left));
      expect(answers.bottom, greaterThan(viewport.height * 0.85));
      expect(answers.bottom, lessThan(viewport.height));

      final seen = <String>{};
      for (var index = 0; index < 10; index++) {
        final choices = tester.widget<AnswerChoices>(
          find.byType(AnswerChoices),
        );
        final question = choices.question;
        expect(seen.add(question.questionKey), isTrue);
        final answer = index == 0
            ? question.options.firstWhere(
                (option) => option != question.correctAnswer,
              )
            : question.correctAnswer;
        final button = find.text('$answer');
        await tester.tap(button);
        choices.onAnswer!(answer);
        await tester.pump(const Duration(milliseconds: 20));
        if (index < 9) {
          expect(find.text('Question ${index + 2} of 10'), findsOneWidget);
          final nextChoices = tester.widget<AnswerChoices>(
            find.byType(AnswerChoices),
          );
          expect(nextChoices.onAnswer, isNull);
        }
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }
      expect(find.text('9 of 10 correct'), findsOneWidget);
      final data = ProfileManager().loadPerformanceData();
      expect(data.length, 10);
      expect(data.values.every((entry) => entry.appearanceCount == 1), isTrue);

      await tapVisible(tester, 'Practice missed facts');
      final choices = tester.widget<AnswerChoices>(find.byType(AnswerChoices));
      expect(choices.question.questionKey, seen.first);
      await tapVisible(tester, '${choices.question.correctAnswer}');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Review complete!'), findsOneWidget);
      expect(
        ProfileManager().loadPerformanceData()[seen.first]!.needsReview,
        isFalse,
      );
    },
  );

  testWidgets(
    'Loads existing progress and supports the numeric keypad in landscape',
    (tester) async {
      await openApp(
        tester,
        viewport: const Size(700, 340),
        textScale: 1.3,
        prefs: {
          'profile_list': ['Ada'],
          'active_profile': 'Ada',
          'profile_Ada_selectedTables': ['2'],
          'profile_Ada_advancedMode': true,
          'profile_Ada_soundEnabled': false,
          'profile_Ada_performanceData': '{"2x3":{"c":2,"w":1,"t":"4.00"}}',
        },
      );
      await tester.tap(find.byTooltip('My progress'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Review 1 missed fact');
      expect(find.text('2 × 3 = ?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.pump();
      expect(find.text('2 × 3 = 6'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tapVisible(tester, 'Done');
      expect(find.text('Review 1 missed fact'), findsNothing);
      final data = ProfileManager().loadPerformanceData()['2x3']!;
      expect(data.appearanceCount, 3);
      expect(data.timesIncorrect, 1);
    },
  );

  testWidgets('Saves table selections and sound settings on a small iPhone', (
    tester,
  ) async {
    await openApp(
      tester,
      viewport: const Size(320, 568),
      textScale: 1.4,
      prefs: {'profile_Default_soundEnabled': true},
    );
    await tester.tap(find.byTooltip('Profiles & settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, '12');
    await tapVisible(tester, 'Game sounds');
    await tapVisible(tester, 'Save');
    final settings = ProfileManager().currentProfile!.settings;
    expect(settings.selectedTables, contains(12));
    expect(settings.soundEnabled, isFalse);
    expect(find.text('Hello, Default!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'All supported multiplication facts have four distinct answer choices',
    () {
      for (var left = 1; left <= 12; left++) {
        for (var right = 1; right <= 12; right++) {
          final question = Question.fromKey('${left}x$right');
          expect(question.options.toSet(), hasLength(4));
          expect(question.options, contains(left * right));
        }
      }
    },
  );

  testWidgets('Game sounds only play for the requested answer controls', (
    tester,
  ) async {
    await openApp(
      tester,
      viewport: const Size(1024, 768),
      prefs: {
        'profile_Default_advancedMode': true,
        'profile_Default_soundEnabled': true,
      },
    );
    final messenger = tester.binding.defaultBinaryMessenger;
    final sounds = {
      for (final file in Directory('assets/audio').listSync().whereType<File>())
        if (file.path.endsWith('.mp3') || file.path.endsWith('.wav'))
          'audio/${file.uri.pathSegments.last}': file.absolute.uri,
    };
    AudioCache.instance.loadedFiles.addAll(sounds);
    addTearDown(
      () => AudioCache.instance.loadedFiles.removeWhere(
        (path, _) => sounds.containsKey(path),
      ),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    final played = <String>[];
    final sources = <String, String>{};
    Future<void> emit(String player, String event, [Object? value]) async {
      await messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$player',
        const StandardMethodCodec().encodeSuccessEnvelope({
          'event': event,
          'value': ?value,
        }),
        null,
      );
    }

    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final player = call.arguments['playerId'] as String;
        switch (call.method) {
          case 'create':
            messenger.setMockMethodCallHandler(
              MethodChannel('xyz.luan/audioplayers/events/$player'),
              (_) async => null,
            );
          case 'setSourceUrl':
            final name = Uri.file(call.arguments['url'] as String)
                .pathSegments
                .last;
            expect(sounds, contains('audio/$name'));
            sources[player] = name;
            await emit(player, 'audio.onPrepared', true);
          case 'resume':
            played.add(player);
          case 'getCurrentPosition':
            return 0;
        }
        return null;
      },
    );

    Future<void> tapWithSound(Finder target, {bool celebration = false}) async {
      final previous = played.length;
      await tester.tap(target);
      await tester.pump();
      final players = played.skip(previous).toList();
      expect(
        players.map((player) => sources[player]),
        unorderedEquals(['tap.mp3', if (celebration) endsWith('.wav')]),
      );
      for (final player in players) {
        await emit(player, 'audio.onComplete');
      }
      await tester.pumpAndSettle();
    }

    Future<void> openQuiz() async {
      await tester.tap(find.bySemanticsLabel('Multiplication quiz'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Start without a timer');
    }

    await tapVisible(tester, 'Mixed practice');
    await tapVisible(tester, 'Show a hint');
    expect(played, isEmpty);
    for (final target in [
      find.text('0'),
      find.text('4'),
      find.byIcon(Icons.backspace_rounded),
      find.byIcon(Icons.check_rounded),
      find.text('Next question'),
    ]) {
      await tapWithSound(target);
    }
    expect(played, hasLength(5));
    await tapVisible(tester, 'Finish');
    await tapVisible(tester, 'Done');
    expect(played, hasLength(5));

    await openQuiz();
    await tapWithSound(find.text('6'));
    await tapWithSound(find.byIcon(Icons.check_rounded));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(played, hasLength(7));

    await tester.tap(find.byTooltip('Profiles & settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Type answers');
    await tapVisible(tester, 'Save');
    await openQuiz();
    final firstChoice = tester
        .widget<AnswerChoices>(find.byType(AnswerChoices))
        .question
        .options
        .first;
    await tapWithSound(find.text('$firstChoice'));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tapVisible(tester, 'Mixed practice');
    final firstPracticeQuestion = tester
        .widget<AnswerChoices>(find.byType(AnswerChoices))
        .question;
    final wrongChoice = firstPracticeQuestion.options.firstWhere(
      (answer) => answer != firstPracticeQuestion.correctAnswer,
    );
    await tapWithSound(find.text('$wrongChoice'));
    await tapWithSound(find.text('Next question'));
    for (var index = 0; index < 5; index++) {
      final question = tester
          .widget<AnswerChoices>(find.byType(AnswerChoices))
          .question;
      await tapWithSound(
        find.text('${question.correctAnswer}'),
        celebration: index == 4,
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
    await tapVisible(tester, 'Finish');
    await tapVisible(tester, 'Done');

    await tester.tap(find.byTooltip('Profiles & settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Game sounds');
    await tapVisible(tester, 'Save');
    final soundsBeforeMutedPractice = played.length;
    await tapVisible(tester, 'Mixed practice');
    final silentChoice = tester
        .widget<AnswerChoices>(find.byType(AnswerChoices))
        .question
        .options
        .first;
    await tapVisible(tester, '$silentChoice');
    expect(played, hasLength(soundsBeforeMutedPractice));
    await tapVisible(tester, 'Finish');
    await tapVisible(tester, 'Done');

    await tester.tap(find.byTooltip('Profiles & settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Type answers');
    await tapVisible(tester, 'Save');
    await tapVisible(tester, 'Mixed practice');
    await tapVisible(tester, '6');
    expect(played, hasLength(soundsBeforeMutedPractice));
  });
}
