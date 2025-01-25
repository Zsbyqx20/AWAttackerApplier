import 'package:flutter/material.dart';

import '../models/rule_validation_result.dart';

/// 验证错误提示组件
class ValidationErrorWidget extends StatelessWidget {
  const ValidationErrorWidget({
    super.key,
    required this.validationResult,
    this.padding = const EdgeInsets.only(top: 4, left: 12),
    this.textStyle,
  });
  final RuleValidationResult? validationResult;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final result = validationResult;
    if (result == null || result.isValid) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final errorCode = result.errorCode;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorCode != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                // ignore: no-magic-number
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              child: Text(
                errorCode,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  // ignore: no-magic-number
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 验证错误提示容器
class ValidationErrorContainer extends StatelessWidget {
  const ValidationErrorContainer({
    super.key,
    required this.validationResult,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius,
  });
  final RuleValidationResult? validationResult;
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final result = validationResult;
    final hasError = result != null && !result.isValid;
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            borderRadius ?? const BorderRadius.all(Radius.circular(8)),
        border: Border.all(
          color: hasError ? theme.colorScheme.error : Colors.grey.shade200,
          // ignore: no-magic-number
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
