class TagActivationException implements Exception {
  final String message;
  final String? tag;
  final String? code;

  TagActivationException(this.message, {this.tag, this.code});

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (tag != null) buffer.write(' (标签: $tag)');
    if (code != null) buffer.write(' [错误码: $code]');
    return buffer.toString();
  }

  static TagActivationException notFound(String tag) {
    return TagActivationException('标签不存在', tag: tag, code: 'TAG_NOT_FOUND');
  }

  static TagActivationException alreadyActive(String tag) {
    return TagActivationException('标签已经激活',
        tag: tag, code: 'TAG_ALREADY_ACTIVE');
  }

  static TagActivationException notActive(String tag) {
    return TagActivationException('标签未激活', tag: tag, code: 'TAG_NOT_ACTIVE');
  }

  static TagActivationException storageError() {
    return TagActivationException('存储操作失败', code: 'STORAGE_ERROR');
  }
}
