import 'package:flutter/material.dart';

import 'package:awattackerapplier/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/widgets/style_editor.dart';

void main() {
  group('ConditionListEditor Tests', () {
    late List<String> conditions;
    late ValueChanged<List<String>> onChanged;

    setUp(() {
      conditions = [];
      onChanged = (List<String> value) {
        conditions = value;
      };
    });

    Future<void> pumpConditionListEditor(
      WidgetTester tester, {
      required String label,
      required List<String> initialConditions,
      required ValueChanged<List<String>> onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: Scaffold(
            body: ConditionListEditor(
              label: label,
              conditions: initialConditions,
              onChanged: onChanged,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('displays empty state hint text', (tester) async {
      await pumpConditionListEditor(
        tester,
        label: 'Test Conditions',
        initialConditions: [],
        onChanged: onChanged,
      );

      // Find the empty state container
      final emptyContainer = find.descendant(
        of: find.byType(ConditionListEditor),
        matching: find.byWidgetPredicate(
            (widget) => widget is Container && widget.child is Center),
      );
      expect(emptyContainer, findsOneWidget);

      // Verify container style
      final containerWidget = tester.widget<Container>(emptyContainer);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey[50]);
      expect(decoration.borderRadius, BorderRadius.circular(8));
      expect(decoration.border?.top.color, Colors.grey[200]);

      // Verify hint text is centered
      final hintText = find.descendant(
        of: emptyContainer,
        matching: find.byType(Text),
      );
      expect(hintText, findsOneWidget);

      final textWidget = tester.widget<Text>(hintText);
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('add and remove conditions', (tester) async {
      await pumpConditionListEditor(
        tester,
        label: 'Test Conditions',
        initialConditions: [],
        onChanged: onChanged,
      );

      // 找到添加按钮 - 使用更精确的定位方式
      final addButton = find.descendant(
        of: find.byType(Row),
        matching: find.byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == 'Add condition'),
      );
      expect(addButton, findsOneWidget);

      // Add condition
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verify input field is added
      expect(find.byType(TextField), findsOneWidget);

      // Enter condition
      await tester.enterText(find.byType(TextField), 'Test Condition');
      await tester.pumpAndSettle();

      // Verify condition is updated
      expect(conditions, ['Test Condition']);

      // 找到删除按钮 - 使用更精确的定位方式
      final removeButton = find.descendant(
        of: find.byType(Row),
        matching: find.byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == 'Remove condition'),
      );
      expect(removeButton, findsOneWidget);

      // Remove condition
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      // Verify condition is removed
      expect(conditions, isEmpty);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('displays number labels', (tester) async {
      await pumpConditionListEditor(
        tester,
        label: 'Test Conditions',
        initialConditions: ['Condition 1', 'Condition 2'],
        onChanged: onChanged,
      );

      // Verify number labels
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify number label style
      final numberContainer = find.descendant(
        of: find.byType(ConditionListEditor),
        matching: find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.child is Text &&
            (widget.child as Text).data == '1'),
      );
      expect(numberContainer, findsOneWidget);

      final container = tester.widget<Container>(numberContainer);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));

      final renderBox = tester.renderObject(numberContainer) as RenderBox;
      expect(renderBox.size.width, 24);
      expect(renderBox.size.height, 24);
    });

    testWidgets('filters out empty conditions', (tester) async {
      await pumpConditionListEditor(
        tester,
        label: 'Test Conditions',
        initialConditions: [],
        onChanged: onChanged,
      );

      // 找到添加按钮
      final addButton = find.descendant(
        of: find.byType(Row),
        matching: find.byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == 'Add condition'),
      );
      expect(addButton, findsOneWidget);

      // Add two conditions
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Enter text only in second field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), 'Valid Condition');
      await tester.pumpAndSettle();

      // Verify only non-empty condition is included
      expect(conditions, ['Valid Condition']);
    });
  });
}
