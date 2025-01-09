import 'package:flutter_test/flutter_test.dart';

import 'package:awattackerapplier/models/rule_validation_result.dart';
import 'package:awattackerapplier/models/rule_validation_state.dart';

void main() {
  group('RuleValidationState', () {
    test('使用默认构造函数创建实例', () {
      final fieldResults = {
        'field1': RuleValidationResult.success(),
        'field2': RuleValidationResult.fieldError('field2', '错误信息'),
      };

      final state = RuleValidationState(
        isValid: false,
        fieldResults: fieldResults,
      );

      expect(state.isValid, isFalse);
      expect(state.fieldResults, equals(fieldResults));
      expect(state.fieldResults.length, equals(2));
      expect(state.fieldResults['field1']?.isValid, isTrue);
      expect(state.fieldResults['field2']?.isValid, isFalse);
    });

    test('initial 工厂方法创建初始状态', () {
      final state = RuleValidationState.initial();

      expect(state.isValid, isTrue);
      expect(state.fieldResults, isEmpty);
    });

    group('copyWith 方法', () {
      test('更新验证状态', () {
        final originalState = RuleValidationState.initial();
        final newState = originalState.copyWith(isValid: false);

        expect(newState.isValid, isFalse);
        expect(newState.fieldResults, equals(originalState.fieldResults));
      });

      test('更新字段结果', () {
        final originalState = RuleValidationState.initial();
        final newFieldResults = {
          'field1': RuleValidationResult.fieldError('field1', '错误信息'),
        };

        final newState = originalState.copyWith(fieldResults: newFieldResults);

        expect(newState.isValid, equals(originalState.isValid));
        expect(newState.fieldResults, equals(newFieldResults));
        expect(newState.fieldResults.length, equals(1));
        expect(newState.fieldResults['field1']?.isValid, isFalse);
      });

      test('同时更新状态和字段结果', () {
        final originalState = RuleValidationState.initial();
        final newFieldResults = {
          'field1': RuleValidationResult.fieldError('field1', '错误信息'),
        };

        final newState = originalState.copyWith(
          isValid: false,
          fieldResults: newFieldResults,
        );

        expect(newState.isValid, isFalse);
        expect(newState.fieldResults, equals(newFieldResults));
      });

      test('不提供参数时返回相同的状态', () {
        final originalState = RuleValidationState(
          isValid: false,
          fieldResults: {
            'field1': RuleValidationResult.fieldError('field1', '错误信息'),
          },
        );

        final newState = originalState.copyWith();

        expect(newState.isValid, equals(originalState.isValid));
        expect(newState.fieldResults, equals(originalState.fieldResults));
      });
    });

    test('字段结果的不可变性', () {
      final originalFieldResults = <String, RuleValidationResult>{
        'field1': RuleValidationResult.success(),
      };

      final state = RuleValidationState(
        isValid: true,
        fieldResults:
            Map<String, RuleValidationResult>.from(originalFieldResults),
      );

      // 尝试修改原始字段结果
      originalFieldResults['field2'] =
          RuleValidationResult.fieldError('field2', '错误信息');

      // 验证状态中的字段结果没有被修改
      expect(state.fieldResults.length, equals(1));
      expect(state.fieldResults.containsKey('field2'), isFalse);
    });

    test('复杂验证状态的创建和访问', () {
      final fieldResults = {
        'name': RuleValidationResult.success(),
        'email': RuleValidationResult.fieldError('email', '无效的邮箱格式'),
        'age': RuleValidationResult.fieldError('age', '年龄必须大于0'),
      };

      final state = RuleValidationState(
        isValid: false,
        fieldResults: fieldResults,
      );

      expect(state.isValid, isFalse);
      expect(state.fieldResults.length, equals(3));

      // 验证成功的字段
      expect(state.fieldResults['name']?.isValid, isTrue);

      // 验证失败的字段
      expect(state.fieldResults['email']?.isValid, isFalse);
      expect(state.fieldResults['email']?.errorMessage, equals('无效的邮箱格式'));

      expect(state.fieldResults['age']?.isValid, isFalse);
      expect(state.fieldResults['age']?.errorMessage, equals('年龄必须大于0'));
    });
  });
}
