import 'package:flutter_test/flutter_test.dart';
import 'package:awattackerapplier/models/rule.dart';
import 'package:awattackerapplier/models/overlay_style.dart';
import 'package:awattackerapplier/utils/rule_merger.dart';
import 'package:flutter/material.dart';

void main() {
  group('RuleMerger', () {
    late Rule existingRule;
    late Rule newRule;
    late OverlayStyle existingStyle;
    late OverlayStyle newStyle;

    setUp(() {
      existingStyle = OverlayStyle(
        uiAutomatorCode: 'existing_code',
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        text: 'Existing',
        horizontalAlign: TextAlign.center,
        verticalAlign: TextAlign.center,
        padding: const EdgeInsets.all(8),
      );

      newStyle = OverlayStyle(
        uiAutomatorCode: 'new_code',
        backgroundColor: Colors.red,
        textColor: Colors.black,
        text: 'New',
        horizontalAlign: TextAlign.center,
        verticalAlign: TextAlign.center,
        padding: const EdgeInsets.all(8),
      );

      existingRule = Rule(
        id: 'existing_id',
        name: 'Existing Rule',
        packageName: 'com.test',
        activityName: '.TestActivity',
        isEnabled: true,
        overlayStyles: [existingStyle],
        tags: const ['tag1'],
      );

      newRule = Rule(
        id: 'new_id',
        name: 'New Rule',
        packageName: 'com.test',
        activityName: '.TestActivity',
        isEnabled: true,
        overlayStyles: [newStyle],
        tags: const ['tag2'],
      );
    });

    test('checkConflict should return success for different package names', () {
      final differentRule = newRule.copyWith(packageName: 'com.different');
      final result = RuleMerger.checkConflict(existingRule, differentRule);
      expect(result.isSuccess, isTrue);
      expect(result.mergedRule, equals(differentRule));
    });

    test('checkConflict should return success for different activity names',
        () {
      final differentRule =
          newRule.copyWith(activityName: '.DifferentActivity');
      final result = RuleMerger.checkConflict(existingRule, differentRule);
      expect(result.isSuccess, isTrue);
      expect(result.mergedRule, equals(differentRule));
    });

    test(
        'checkConflict should return mergeable for same package and activity but different UI Automator code',
        () {
      final result = RuleMerger.checkConflict(existingRule, newRule);
      expect(result.isMergeable, isTrue);
      expect(result.mergedRule?.overlayStyles.length, equals(2));
      expect(result.mergedRule?.tags.length, equals(2));
    });

    test('checkConflict should return conflict for same UI Automator code', () {
      final conflictingRule = newRule.copyWith(
        overlayStyles: [existingStyle.copyWith()],
      );
      final result = RuleMerger.checkConflict(existingRule, conflictingRule);
      expect(result.isConflict, isTrue);
      expect(result.errorMessage, isNotNull);
    });

    test('checkConflicts should handle multiple rules correctly', () {
      final rules = [
        existingRule,
        existingRule.copyWith(
          id: 'other_id',
          packageName: 'com.other',
        ),
      ];

      final newRules = [
        newRule,
        newRule.copyWith(
          id: 'different_id',
          packageName: 'com.different',
        ),
      ];

      final results = RuleMerger.checkConflicts(rules, newRules);
      expect(results.length, equals(2));
      expect(results.where((r) => r.isMergeable).length, equals(1));
      expect(results.where((r) => r.isSuccess).length, equals(1));
    });
  });
}
