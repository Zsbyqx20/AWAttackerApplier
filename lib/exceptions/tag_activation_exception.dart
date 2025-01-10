class TagActivationException implements Exception {
  final String message;
  final String? tag;
  final String? code;

  TagActivationException(this.message, {this.tag, this.code});

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (tag != null) buffer.write(' (Tag: $tag)');
    if (code != null) buffer.write(' [$code]');
    return buffer.toString();
  }

  static TagActivationException notFound(String tag) {
    return TagActivationException('Tag not found',
        tag: tag, code: 'TAG_NOT_FOUND');
  }

  static TagActivationException alreadyActive(String tag) {
    return TagActivationException('Tag already active',
        tag: tag, code: 'TAG_ALREADY_ACTIVE');
  }

  static TagActivationException notActive(String tag) {
    return TagActivationException('Tag not active',
        tag: tag, code: 'TAG_NOT_ACTIVE');
  }

  static TagActivationException storageError() {
    return TagActivationException('Storage operation failed',
        code: 'STORAGE_ERROR');
  }
}
