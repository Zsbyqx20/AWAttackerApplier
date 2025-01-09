import 'package:flutter/foundation.dart';

import 'overlay_style.dart';

class Rule {
  final String name;
  final String packageName;
  final String activityName;
  final bool isEnabled;
  final List<OverlayStyle> overlayStyles;
  final List<String> tags;

  Rule({
    required this.name,
    required this.packageName,
    required this.activityName,
    required this.isEnabled,
    required this.overlayStyles,
    List<String>? tags,
  }) : tags = tags ?? [];

  Rule copyWith({
    String? name,
    String? packageName,
    String? activityName,
    bool? isEnabled,
    List<OverlayStyle>? overlayStyles,
    List<String>? tags,
  }) {
    return Rule(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      activityName: activityName ?? this.activityName,
      isEnabled: isEnabled ?? this.isEnabled,
      overlayStyles: overlayStyles ?? this.overlayStyles,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'activityName': activityName,
      'isEnabled': isEnabled,
      'overlayStyles': overlayStyles.map((style) => style.toJson()).toList(),
      'tags': tags,
    };
  }

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      name: json['name'] as String,
      packageName: json['packageName'] as String,
      activityName: json['activityName'] as String,
      isEnabled: json['isEnabled'] as bool,
      overlayStyles: (json['overlayStyles'] as List)
          .map((style) => OverlayStyle.fromJson(style as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List?)?.map((e) => e as String).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rule &&
        other.name == name &&
        other.packageName == packageName &&
        other.activityName == activityName &&
        other.isEnabled == isEnabled &&
        listEquals(other.overlayStyles, overlayStyles) &&
        setEquals(Set<String>.from(other.tags), Set<String>.from(tags));
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      packageName,
      activityName,
      isEnabled,
      Object.hashAll(overlayStyles),
      Object.hashAll(tags.toSet().toList()..sort()),
    );
  }

  @override
  String toString() {
    return 'Rule{name: $name, packageName: $packageName, activityName: $activityName, isEnabled: $isEnabled, overlayStyles: ${overlayStyles.length}, tags: $tags}';
  }
}
