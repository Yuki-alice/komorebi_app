import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'performance_monitor.dart';

/// 性能报告导出器
///
/// 支持导出为 JSON 报告和分享功能。
class PerformanceReportExporter {
  static final PerformanceReportExporter _instance = PerformanceReportExporter._internal();
  factory PerformanceReportExporter() => _instance;
  PerformanceReportExporter._internal();

  final CustomPerformanceMonitor _monitor = CustomPerformanceMonitor();

  /// 生成并导出 JSON 报告到文件
  Future<File> exportJsonReport() async {
    return await _monitor.exportReport();
  }

  /// 生成并导出日志到文件
  Future<File> exportLogs() async {
    return await _monitor.exportLogs();
  }

  /// 生成 Markdown 格式的可读报告
  Future<File> exportMarkdownReport() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/performance_report.md');

    final report = _monitor.getReport();
    final stats = report['stats'] as Map<String, dynamic>? ?? {};
    final totalLogs = report['totalLogs'] as int? ?? 0;
    final generatedAt = report['generatedAt'] as String? ?? DateTime.now().toIso8601String();

    final buffer = StringBuffer();
    buffer.writeln('# Komorebi 性能监控报告');
    buffer.writeln();
    buffer.writeln('- **生成时间**: $generatedAt');
    buffer.writeln('- **总日志数**: $totalLogs');
    buffer.writeln();

    if (stats.isEmpty) {
      buffer.writeln('暂无性能数据。');
    } else {
      buffer.writeln('## 性能统计');
      buffer.writeln();
      buffer.writeln('| 标签 | 次数 | 总耗时(ms) | 平均耗时(ms) | 最大耗时(ms) | 最小耗时(ms) |');
      buffer.writeln('|------|------|------------|--------------|--------------|--------------|');

      // 按平均耗时降序排列
      final sortedEntries = stats.entries.toList()
        ..sort((a, b) {
          final aAvg = double.tryParse((a.value as Map)['avgMs'].toString()) ?? 0;
          final bAvg = double.tryParse((b.value as Map)['avgMs'].toString()) ?? 0;
          return bAvg.compareTo(aAvg);
        });

      for (final entry in sortedEntries) {
        final label = entry.key;
        final data = entry.value as Map<String, dynamic>;
        final count = data['count'] ?? 0;
        final totalMs = data['totalMs'] ?? 0;
        final avgMs = data['avgMs'] ?? '0.00';
        final maxMs = data['maxMs'] ?? 0;
        final minMs = data['minMs'] ?? 0;

        buffer.writeln('| $label | $count | $totalMs | $avgMs | $maxMs | $minMs |');
      }
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*由 Komorebi 性能监控系统自动生成*');

    await file.writeAsString(buffer.toString());
    return file;
  }

  /// 分享性能报告（使用系统分享面板）
  Future<void> shareReport({bool markdown = true}) async {
    try {
      final file = markdown
          ? await exportMarkdownReport()
          : await exportJsonReport();

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Komorebi 性能监控报告',
        text: '请查收 Komorebi 应用的性能监控报告。',
      );
    } catch (e) {
      debugPrint('分享性能报告失败: $e');
    }
  }

  /// 获取最近的慢操作（超过阈值的记录）
  List<Map<String, dynamic>> getRecentSlowOperations({int thresholdMs = 1000, int limit = 20}) {
    final logs = _monitor.getRecentLogs(count: _monitor.logCount);
    final slowLogs = logs
        .where((log) => log.durationMs > thresholdMs)
        .take(limit)
        .map((log) => log.toJson())
        .toList();
    return slowLogs;
  }

  /// 获取性能摘要（用于 UI 展示）
  Map<String, dynamic> getPerformanceSummary() {
    final report = _monitor.getReport();
    final stats = report['stats'] as Map<String, dynamic>? ?? {};

    if (stats.isEmpty) {
      return {'status': '暂无数据', 'totalOperations': 0};
    }

    int totalOps = 0;
    int totalMs = 0;
    int maxMs = 0;

    for (final data in stats.values) {
      final map = data as Map<String, dynamic>;
      totalOps += (map['count'] as int? ?? 0);
      totalMs += (map['totalMs'] as int? ?? 0);
      final currentMax = map['maxMs'] as int? ?? 0;
      if (currentMax > maxMs) maxMs = currentMax;
    }

    final avgMs = totalOps > 0 ? totalMs / totalOps : 0;

    return {
      'status': maxMs > 1000 ? '存在慢操作' : '性能良好',
      'totalOperations': totalOps,
      'totalDurationMs': totalMs,
      'averageDurationMs': avgMs.toStringAsFixed(2),
      'maxDurationMs': maxMs,
      'operationCount': stats.length,
    };
  }
}
