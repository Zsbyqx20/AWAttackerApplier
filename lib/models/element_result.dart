class ElementResult {
  final bool success;
  final String? message;
  final Map<String, int>? coordinates;
  final Map<String, int>? size;
  final bool? visible;

  ElementResult({
    required this.success,
    this.message,
    this.coordinates,
    this.size,
    this.visible,
  });

  factory ElementResult.fromMap(Map<String, dynamic> map) {
    return ElementResult(
      success: map['success'] as bool,
      message: map['message'] as String?,
      coordinates: map['coordinates'] != null
          ? Map<String, int>.from(map['coordinates'])
          : null,
      size: map['size'] != null ? Map<String, int>.from(map['size']) : null,
      visible: map['visible'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'coordinates': coordinates,
      'size': size,
      'visible': visible,
    };
  }
}
