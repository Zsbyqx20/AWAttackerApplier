import 'package:flutter_test/flutter_test.dart';
import 'package:awattackerapplier/models/rule.dart';
import 'package:awattackerapplier/models/rule_merge_result.dart';
import 'package:awattackerapplier/models/rule_conflict_type.dart';

void main() {
  group('RuleMergeResult', () {
    late Rule testRule;

    setUp(() {
      testRule = Rule(
        name: 'Test Rule',
        packageName: 'com.test',
        activityName: '.TestActivity',
        isEnabled: true,
        overlayStyles: const [],
        tags: const [],
      );
    });

    test('success factory should create correct result', () {
      final result = RuleMergeResult.success(testRule);
      expect(result.mergedRule, equals(testRule));
      expect(result.conflictType, equals(RuleConflictType.none));
      expect(result.errorMessage, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.isMergeable, isFalse);
      expect(result.isConflict, isFalse);
    });

    test('mergeable factory should create correct result', () {
      final result = RuleMergeResult.mergeable(testRule);
      expect(result.mergedRule, equals(testRule));
      expect(result.conflictType, equals(RuleConflictType.mergeable));
      expect(result.errorMessage, isNull);
      expect(result.isSuccess, isFalse);
      expect(result.isMergeable, isTrue);
      expect(result.isConflict, isFalse);
    });

    test('conflict factory should create correct result', () {
      const errorMessage = 'Test error';
      final result = RuleMergeResult.conflict(errorMessage: errorMessage);
      expect(result.mergedRule, isNull);
      expect(result.conflictType, equals(RuleConflictType.conflict));
      expect(result.errorMessage, equals(errorMessage));
      expect(result.isSuccess, isFalse);
      expect(result.isMergeable, isFalse);
      expect(result.isConflict, isTrue);
    });

    test('toString should include all non-null fields', () {
      final successResult = RuleMergeResult.success(testRule);
      expect(successResult.toString(), contains('conflictType: none'));
      expect(successResult.toString(), contains('mergedRule:'));

      final conflictResult =
          RuleMergeResult.conflict(errorMessage: 'Test error');
      expect(conflictResult.toString(), contains('conflictType: conflict'));
      expect(conflictResult.toString(), contains('errorMessage: Test error'));
    });
  });
}
