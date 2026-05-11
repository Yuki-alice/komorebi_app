import 'performance_monitor.dart';

/// 性能追踪便捷工具
///
/// 使用示例：
/// ```dart
/// // 追踪异步操作
/// final notes = await Perf.trace(
///   'repo.getAllNotes',
///   () => repo.getAllNotes(),
/// );
///
/// // 追踪同步操作
/// final result = Perf.traceSync(
///   'utils.parseJson',
///   () => parseJson(data),
/// );
///
/// // 追踪带元数据的操作
/// final syncResult = await Perf.trace(
///   'sync.notes',
///   () => syncService.syncNotes(),
///   metadata: {'noteCount': notes.length},
/// );
/// ```
class Perf {
  static final CustomPerformanceMonitor _monitor = CustomPerformanceMonitor();

  /// 追踪异步操作
  static Future<T> trace<T>(
    String label,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      stopwatch.stop();
      _monitor.record(label, stopwatch.elapsedMilliseconds, metadata: metadata);
    }
  }

  /// 追踪同步操作
  static T traceSync<T>(
    String label,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    final stopwatch = Stopwatch()..start();
    try {
      return operation();
    } finally {
      stopwatch.stop();
      _monitor.record(label, stopwatch.elapsedMilliseconds, metadata: metadata);
    }
  }

  /// 开始一个手动计时的追踪
  static PerfTrace start(String label, {Map<String, dynamic>? metadata}) {
    return PerfTrace._(label, metadata);
  }

  /// 获取监控器实例（用于高级操作）
  static CustomPerformanceMonitor get monitor => _monitor;

  /// 获取统计报告
  static Map<String, dynamic> get report => _monitor.getReport();

  /// 导出日志文件
  static Future exportLogs() => _monitor.exportLogs();

  /// 清空日志
  static void clear() => _monitor.clear();

  /// 启用/禁用监控
  static set enabled(bool value) => _monitor.setEnabled(value);
}

/// 手动计时追踪器
class PerfTrace {
  final String _label;
  final Map<String, dynamic>? _metadata;
  final Stopwatch _stopwatch;
  bool _stopped = false;

  PerfTrace._(this._label, this._metadata)
      : _stopwatch = Stopwatch()..start();

  /// 停止追踪并记录
  void stop({Map<String, dynamic>? additionalMetadata}) {
    if (_stopped) return;
    _stopped = true;
    _stopwatch.stop();

    final mergedMetadata = <String, dynamic>{};
    if (_metadata != null) mergedMetadata.addAll(_metadata!);
    if (additionalMetadata != null) mergedMetadata.addAll(additionalMetadata);

    Perf.monitor.record(
      _label,
      _stopwatch.elapsedMilliseconds,
      metadata: mergedMetadata.isEmpty ? null : mergedMetadata,
    );
  }

  /// 自动在 Future 完成时停止
  Future<T> wrap<T>(Future<T> future) async {
    try {
      return await future;
    } finally {
      stop();
    }
  }
}
