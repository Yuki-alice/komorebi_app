// 网络异常重试机制
// 提供带指数退避的重试包装器，用于所有 Supabase 网络操作。
// 处理 TimeoutException、SocketException 等常见网络异常。

import 'dart:io';
import 'dart:async';

import 'sync_models.dart';

class SupabaseRetryWrapper {
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration networkTimeout = Duration(seconds: 15);

  const SupabaseRetryWrapper();

  /// 带重试的网络操作包装器
  ///
  /// [operation] 要执行的网络操作
  /// [operationName] 操作名称（用于日志）
  /// [maxAttempts] 最大重试次数（默认3次）
  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxAttempts = maxRetryAttempts,
  }) async {
    int attempts = 0;
    Duration delay = retryDelay;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        SyncLogger.info('RETRY', '[$operationName] 第 $attempts/$maxAttempts 次尝试');
        final result = await operation().timeout(networkTimeout);
        if (attempts > 1) {
          SyncLogger.info('RETRY', '[$operationName] 重试成功！');
        }
        return result;
      } on TimeoutException catch (e) {
        SyncLogger.warn('RETRY', '[$operationName] 超时 (${e.duration?.inSeconds}s)');
        if (attempts >= maxAttempts) {
          throw SyncException(
            '[$operationName] 操作超时，已重试 $maxAttempts 次',
            type: SyncErrorType.timeout,
          );
        }
      } on SocketException catch (e) {
        SyncLogger.warn('RETRY', '[$operationName] 网络错误: ${e.message}');
        if (attempts >= maxAttempts) {
          throw SyncException(
            '[$operationName] 网络连接失败，请检查网络设置',
            type: SyncErrorType.network,
          );
        }
      } catch (e) {
        SyncLogger.error('RETRY', '[$operationName] 错误', e);
        if (attempts >= maxAttempts) {
          throw SyncException(
            '[$operationName] 操作失败: $e',
            type: SyncErrorType.unknown,
          );
        }
      }

      // 指数退避：每次重试延迟增加
      if (attempts < maxAttempts) {
        SyncLogger.info('RETRY', '[$operationName] ${delay.inSeconds}秒后重试...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }

    throw SyncException(
      '[$operationName] 重试次数耗尽',
      type: SyncErrorType.unknown,
    );
  }
}
