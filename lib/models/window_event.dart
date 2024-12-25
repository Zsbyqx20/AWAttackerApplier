class WindowEvent {
  final String type;
  final String packageName;
  final String activityName;
  final int timestamp;
  final bool sourceChanged;

  WindowEvent({
    required this.type,
    required this.packageName,
    required this.activityName,
    required this.timestamp,
    this.sourceChanged = false,
  });

  factory WindowEvent.fromJson(Map<String, dynamic> json) {
    return WindowEvent(
      type: json['type'] as String,
      packageName: json['package_name'] as String,
      activityName: json['activity_name'] as String,
      timestamp: json['timestamp'] as int,
      sourceChanged: json['source_changed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'package_name': packageName,
      'activity_name': activityName,
      'timestamp': timestamp,
      'source_changed': sourceChanged,
    };
  }
}
