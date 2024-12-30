import 'package:flutter_test/flutter_test.dart';
import 'package:awattackerapplier/models/rule_conflict_type.dart';

void main() {
  group('RuleConflictType', () {
    test('description should return correct string for none', () {
      expect(RuleConflictType.none.description, '无冲突');
    });

    test('description should return correct string for mergeable', () {
      expect(RuleConflictType.mergeable.description, '可合并');
    });

    test('description should return correct string for conflict', () {
      expect(RuleConflictType.conflict.description, '完全冲突');
    });
  });
}
