import 'dart:convert';
import 'dart:io';

import 'package:awattackerapplier/models/rule.dart';
import 'package:awattackerapplier/models/window_event.dart';

/// 创建测试用的窗口事件
WindowEvent createTestWindowEvent({
  String type = 'WINDOW_STATE_CHANGED',
  String packageName = 'com.example.app',
  String activityName = '.MainActivity',
  bool contentChanged = false,
}) {
  return WindowEvent.fromJson({
    'type': type,
    'package_name': packageName,
    'activity_name': activityName,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'content_changed': contentChanged,
  });
}

/// 从测试规则文件加载规则
Future<List<Rule>> loadTestRules() async {
  final file = File('test/fixtures/test_rule.json');
  final jsonData =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final List<dynamic> rulesJson = jsonData['rules'] as List<dynamic>;
  return rulesJson
      .map((e) => Rule.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 从测试规则文件加载可合并的规则
Future<List<Rule>> loadMergeableRules() async {
  final file = File('test/fixtures/test_mergeable_rule.json');
  final jsonData =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final List<dynamic> rulesJson = jsonData['rules'] as List<dynamic>;
  return rulesJson
      .map((e) => Rule.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 从测试规则文件加载冲突的规则
Future<List<Rule>> loadConflictingRules() async {
  final file = File('test/fixtures/test_conflicting_rule.json');
  final jsonData =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final List<dynamic> rulesJson = jsonData['rules'] as List<dynamic>;
  return rulesJson
      .map((e) => Rule.fromJson(e as Map<String, dynamic>))
      .toList();
}
