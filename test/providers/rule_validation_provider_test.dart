import 'package:flutter_test/flutter_test.dart';
import 'package:awattackerapplier/providers/rule_validation_provider.dart';

void main() {
  group('RuleValidationProvider', () {
    late RuleValidationProvider provider;

    setUp(() {
      provider = RuleValidationProvider();
    });

    test('初始状态应该是有效的且没有验证结果', () {
      expect(provider.state.isValid, isTrue);
      expect(provider.state.fieldResults, isEmpty);
    });

    group('validateField', () {
      test('验证规则名称', () {
        provider.validateField('name', '测试规则');
        expect(provider.state.isValid, isTrue);
        expect(provider.state.fieldResults['name']?.isValid, isTrue);

        provider.validateField('name', '');
        expect(provider.state.isValid, isFalse);
        expect(provider.state.fieldResults['name']?.isValid, isFalse);
        expect(
          provider.state.fieldResults['name']?.errorMessage,
          equals('规则名称不能为空'),
        );
      });

      test('验证包名', () {
        provider.validateField('packageName', 'com.example.app');
        expect(provider.state.isValid, isTrue);
        expect(provider.state.fieldResults['packageName']?.isValid, isTrue);

        provider.validateField('packageName', '.invalid.package');
        expect(provider.state.isValid, isFalse);
        expect(provider.state.fieldResults['packageName']?.isValid, isFalse);
      });

      test('验证活动名', () {
        provider.validateField('activityName', '.MainActivity');
        expect(provider.state.isValid, isTrue);
        expect(provider.state.fieldResults['activityName']?.isValid, isTrue);

        provider.validateField('activityName', 'MainActivity');
        expect(provider.state.isValid, isFalse);
        expect(provider.state.fieldResults['activityName']?.isValid, isFalse);
        expect(
          provider.state.fieldResults['activityName']?.errorDetails,
          equals('字段 activityName: 活动名必须以点号(.)开头'),
        );
      });

      test('验证标签列表', () {
        provider.validateField('tags', ['tag1', 'tag2']);
        expect(provider.state.isValid, isTrue);
        expect(provider.state.fieldResults['tags']?.isValid, isTrue);

        provider.validateField('tags', ['tag1', '', 'tag3']);
        expect(provider.state.isValid, isFalse);
        expect(provider.state.fieldResults['tags']?.isValid, isFalse);
        expect(
          provider.state.fieldResults['tags']?.errorDetails,
          equals('字段 tags: 标签不能为空'),
        );
      });

      test('验证未知字段', () {
        provider.validateField('unknown', 'value');
        expect(provider.state.isValid, isFalse);
        expect(provider.state.fieldResults['unknown']?.isValid, isFalse);
        expect(
          provider.state.fieldResults['unknown']?.errorMessage,
          equals('未知字段'),
        );
      });
    });

    group('clearFieldValidation', () {
      test('清除单个字段的验证结果', () {
        // 先添加一些验证结果
        provider.validateField('name', '');
        provider.validateField('packageName', '.invalid');
        expect(provider.state.fieldResults.length, equals(2));

        // 清除一个字段的验证结果
        provider.clearFieldValidation('name');
        expect(provider.state.fieldResults.length, equals(1));
        expect(provider.state.fieldResults.containsKey('name'), isFalse);
        expect(provider.state.fieldResults.containsKey('packageName'), isTrue);
      });
    });

    group('clearAllValidations', () {
      test('清除所有验证结果', () {
        // 先添加一些验证结果
        provider.validateField('name', '');
        provider.validateField('packageName', '.invalid');
        provider.validateField('activityName', 'MainActivity');
        expect(provider.state.fieldResults.length, equals(3));

        // 清除所有验证结果
        provider.clearAllValidations();
        expect(provider.state.fieldResults, isEmpty);
        expect(provider.state.isValid, isTrue);
      });
    });

    test('监听器应该在状态改变时被调用', () {
      var listenerCallCount = 0;
      provider.addListener(() {
        listenerCallCount++;
      });

      provider.validateField('name', '测试规则');
      expect(listenerCallCount, equals(1));

      provider.validateField('name', '');
      expect(listenerCallCount, equals(2));

      provider.clearFieldValidation('name');
      expect(listenerCallCount, equals(3));

      provider.clearAllValidations();
      expect(listenerCallCount, equals(4));
    });
  });
}
