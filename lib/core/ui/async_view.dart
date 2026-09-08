/// حالات الشاشة الحتمية (§83) — تحميل/فارغ/خطأ/دون اتصال، لا شاشة بيضاء.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../errors/api_exception.dart';

/// ترجمة خطأ إلى نص عرض — التفريع على `code` حصراً (§31)، مع إظهار رسالة
/// الخادم العربية حيث تكون أدق، و`request_id` للتفاصيل التقنية.
String describeError(BuildContext context, Object error) {
  final l = AppLocalizations.of(context)!;
  if (error is NetworkException) return l.errNetwork;
  if (error is! ApiException) return l.stateError;
  final serverMsg = error.message.isNotEmpty ? error.message : null;
  return switch (error.code) {
    ApiErrorCode.unauthenticated => l.errUnauthenticated,
    ApiErrorCode.forbidden || ApiErrorCode.insufficientScope => l.errForbidden,
    ApiErrorCode.resourceNotFound => l.errNotFound,
    ApiErrorCode.validationFailed => serverMsg ?? l.errValidation,
    ApiErrorCode.rateLimited => l.errRateLimited,
    ApiErrorCode.maintenance => l.maintenanceBody,
    ApiErrorCode.lockdown => l.lockdownBody,
    ApiErrorCode.accountRestricted => serverMsg ?? l.accountRestricted,
    ApiErrorCode.sessionRevoked => l.sessionRevoked,
    ApiErrorCode.serviceUnavailable => l.serverUnavailable,
    ApiErrorCode.businessRuleViolation ||
    ApiErrorCode.conflict ||
    ApiErrorCode.versionConflict ||
    ApiErrorCode.approvalRequired ||
    ApiErrorCode.locked => serverMsg ?? l.stateError,
    _ => serverMsg ?? l.errServer,
  };
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final requestId = error is ApiException
        ? (error as ApiException).requestId
        : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(describeError(context, error), textAlign: TextAlign.center),
            if (requestId != null) ...[
              const SizedBox(height: 8),
              Text(
                l.errRequestId(requestId),
                style: Theme.of(context).textTheme.bodySmall,
                textDirection: TextDirection.ltr,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message, this.icon = Icons.inbox_outlined});

  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message ?? AppLocalizations.of(context)!.stateEmpty),
      ],
    ),
  );
}

/// غلاف قياسي لمحتوى غير متزامن.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.loading,
    this.error,
    required this.value,
    required this.builder,
    this.onRetry,
    this.emptyWhen,
    this.emptyMessage,
  });

  final bool loading;
  final Object? error;
  final T? value;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback? onRetry;
  final bool Function(T)? emptyWhen;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v != null) {
      if (emptyWhen?.call(v) ?? false) {
        return EmptyView(message: emptyMessage);
      }
      return builder(context, v);
    }
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return ErrorView(error: error!, onRetry: onRetry);
    return EmptyView(message: emptyMessage);
  }
}
