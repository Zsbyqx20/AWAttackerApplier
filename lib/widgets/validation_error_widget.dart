import 'package:flutter/material.dart';

import '../models/rule_validation_result.dart';

/// 验证错误提示组件
class ValidationErrorWidget extends StatelessWidget {
  final RuleValidationResult? validationResult;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  const ValidationErrorWidget({
    super.key,
    required this.validationResult,
    this.padding = const EdgeInsets.only(top: 4, left: 12),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (validationResult == null || validationResult!.isValid) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final defaultStyle = TextStyle(
      color: theme.colorScheme.error,
      fontSize: 12,
    );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 14,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              validationResult!.errorMessage ?? '验证错误',
              style: textStyle ?? defaultStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// 验证错误提示容器
class ValidationErrorContainer extends StatelessWidget {
  final RuleValidationResult? validationResult;
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const ValidationErrorContainer({
    super.key,
    required this.validationResult,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = validationResult != null && !validationResult!.isValid;
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? theme.colorScheme.error : Colors.grey[200]!,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          ValidationErrorWidget(validationResult: validationResult),
        ],
      ),
    );
  }
}
