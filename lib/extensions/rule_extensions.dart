import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/rule.dart';

extension RuleExtensions on Rule {
  /// 生成规则的哈希值，基于规则的关键内容（不包括id和isEnabled）
  String generateHashId() {
    final map = {
      'name': name,
      'packageName': packageName,
      'activityName': activityName,
      'overlayStyles': overlayStyles.map((s) => s.toJson()).toList(),
      'tags': tags,
    };
    return sha256.convert(utf8.encode(json.encode(map))).toString();
  }

  /// 检查规则是否与另一个规则内容相同（不考虑id和isEnabled）
  bool contentEquals(Rule other) {
    return name == other.name &&
        packageName == other.packageName &&
        activityName == other.activityName &&
        listEquals(overlayStyles, other.overlayStyles) &&
        listEquals(tags, other.tags);
  }
}
