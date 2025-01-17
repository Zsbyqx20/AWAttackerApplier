import 'dart:convert';

enum WindowEventType {
  serviceConnected,
  windowEvent,
}

class WindowEvent {
  final WindowEventType type;
  final int timestamp;
  final bool isFirstConnect;

  const WindowEvent({
    required this.type,
    required this.timestamp,
    this.isFirstConnect = false,
  });

  factory WindowEvent.fromJson(String jsonStr) {
    final json = jsonDecode(jsonStr);
    return WindowEvent(
      type: _parseEventType(json['type'] as String),
      timestamp: json['timestamp'] as int,
      isFirstConnect: json['is_first_connect'] as bool? ?? false,
    );
  }

  static WindowEventType _parseEventType(String type) {
    switch (type) {
      case 'SERVICE_CONNECTED':
        return WindowEventType.serviceConnected;
      case 'WINDOW_EVENT':
        return WindowEventType.windowEvent;
      default:
        throw ArgumentError('Unknown event type: $type');
    }
  }

  @override
  String toString() =>
      'WindowEvent(type: $type, timestamp: $timestamp, isFirstConnect: $isFirstConnect)';
}
