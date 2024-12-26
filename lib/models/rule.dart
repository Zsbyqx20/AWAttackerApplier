import 'overlay_style.dart';

class Rule {
  final String id;
  final String name;
  final String packageName;
  final String activityName;
  final bool isEnabled;
  final List<OverlayStyle> overlayStyles;

  Rule({
    required this.id,
    required this.name,
    required this.packageName,
    required this.activityName,
    required this.isEnabled,
    required this.overlayStyles,
  });

  Rule copyWith({
    String? id,
    String? name,
    String? packageName,
    String? activityName,
    bool? isEnabled,
    List<OverlayStyle>? overlayStyles,
  }) {
    return Rule(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      activityName: activityName ?? this.activityName,
      isEnabled: isEnabled ?? this.isEnabled,
      overlayStyles: overlayStyles ?? this.overlayStyles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'packageName': packageName,
      'activityName': activityName,
      'isEnabled': isEnabled,
      'overlayStyles': overlayStyles.map((style) => style.toJson()).toList(),
    };
  }

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      id: json['id'] as String,
      name: json['name'] as String,
      packageName: json['packageName'] as String,
      activityName: json['activityName'] as String,
      isEnabled: json['isEnabled'] as bool,
      overlayStyles: (json['overlayStyles'] as List)
          .map((style) => OverlayStyle.fromJson(style as Map<String, dynamic>))
          .toList(),
    );
  }
}
