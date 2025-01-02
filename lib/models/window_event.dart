class WindowEvent {
  final String type;
  final String? packageName;
  final String? activityName;
  final int timestamp;
  final bool contentChanged;

  WindowEvent({
    required this.type,
    this.packageName,
    this.activityName,
    required this.timestamp,
    this.contentChanged = false,
  });

  factory WindowEvent.fromJson(Map<String, dynamic> json) {
    return WindowEvent(
      type: json['type'] as String,
      packageName: json['package_name'] as String?,
      activityName: json['activity_name'] as String?,
      timestamp: json['timestamp'] as int,
      contentChanged: json['content_changed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'package_name': packageName,
      'activity_name': activityName,
      'timestamp': timestamp,
      'content_changed': contentChanged,
    };
  }
}
