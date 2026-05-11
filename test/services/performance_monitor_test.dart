import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/core/services/performance/performance_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomPerformanceMonitor', () {
    late CustomPerformanceMonitor monitor;

    setUp(() {
      monitor = CustomPerformanceMonitor();
      monitor.clear();
      monitor.setEnabled(true);
    });

    test('should record performance log', () {
      monitor.record('test.op', 150);

      expect(monitor.logCount, equals(1));

      final stats = monitor.getStats('test.op');
      expect(stats, isNotNull);
      expect(stats!.count, equals(1));
      expect(stats.totalMs, equals(150));
      expect(stats.avgMs, equals(150.0));
      expect(stats.maxMs, equals(150));
      expect(stats.minMs, equals(150));
    });

    test('should calculate stats for multiple records', () {
      monitor.record('test.op', 100);
      monitor.record('test.op', 200);
      monitor.record('test.op', 300);

      final stats = monitor.getStats('test.op');
      expect(stats, isNotNull);
      expect(stats!.count, equals(3));
      expect(stats.totalMs, equals(600));
      expect(stats.avgMs, equals(200.0));
      expect(stats.maxMs, equals(300));
      expect(stats.minMs, equals(100));
    });

    test('should handle multiple labels independently', () {
      monitor.record('op.a', 100);
      monitor.record('op.b', 200);
      monitor.record('op.a', 300);

      final statsA = monitor.getStats('op.a');
      final statsB = monitor.getStats('op.b');

      expect(statsA!.count, equals(2));
      expect(statsB!.count, equals(1));
      expect(statsA.avgMs, equals(200.0));
      expect(statsB.avgMs, equals(200.0));
    });

    test('should respect enabled flag', () {
      monitor.setEnabled(false);
      monitor.record('test.op', 100);

      expect(monitor.logCount, equals(0));
      expect(monitor.getStats('test.op'), isNull);
    });

    test('should limit max log count', () {
      for (var i = 0; i < 1005; i++) {
        monitor.record('test.op', i);
      }

      expect(monitor.logCount, equals(1000));
    });

    test('should generate report', () {
      monitor.record('op.a', 100);
      monitor.record('op.b', 200);

      final report = monitor.getReport();
      expect(report['totalLogs'], equals(2));
      expect(report.containsKey('generatedAt'), isTrue);
      expect(report.containsKey('stats'), isTrue);

      final stats = report['stats'] as Map<String, dynamic>;
      expect(stats.containsKey('op.a'), isTrue);
      expect(stats.containsKey('op.b'), isTrue);
    });

    test('should get recent logs', () {
      for (var i = 0; i < 10; i++) {
        monitor.record('test.op', i * 10);
      }

      final recent = monitor.getRecentLogs(count: 5);
      expect(recent.length, equals(5));
      // 最近的日志应该是最后插入的
      expect(recent.last.durationMs, equals(90));
    });

    test('should clear all logs', () {
      monitor.record('test.op', 100);
      expect(monitor.logCount, equals(1));

      monitor.clear();
      expect(monitor.logCount, equals(0));
      expect(monitor.getStats('test.op'), isNull);
    });

    test('should export report to file', () async {
      monitor.record('test.op', 150, metadata: {'key': 'value'});

      // 使用临时目录替代 path_provider
      final tempDir = Directory.systemTemp.createTempSync('perf_test_');
      final file = File('${tempDir.path}/performance_report.json');
      await file.writeAsString(jsonEncode(monitor.getReport()));

      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content.contains('test.op'), isTrue);
      expect(content.contains('150'), isTrue);

      // 清理
      await file.delete();
      tempDir.deleteSync();
    });

    test('should export logs to file', () async {
      monitor.record('test.op', 100);
      monitor.record('test.op2', 200);

      // 使用临时目录替代 path_provider
      final tempDir = Directory.systemTemp.createTempSync('perf_test_');
      final file = File('${tempDir.path}/performance_logs.json');
      final logs = monitor.getRecentLogs(count: monitor.logCount);
      await file.writeAsString(jsonEncode(logs.map((l) => l.toJson()).toList()));

      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      expect(decoded.length, equals(2));

      // 清理
      await file.delete();
      tempDir.deleteSync();
    });

    test('should return null stats for unknown label', () {
      final stats = monitor.getStats('unknown');
      expect(stats, isNull);
    });

    test('should handle metadata in records', () {
      monitor.record('test.op', 100, metadata: {'count': 5, 'source': 'test'});

      final logs = monitor.getRecentLogs(count: 1);
      expect(logs.first.metadata, isNotNull);
      expect(logs.first.metadata!['count'], equals(5));
      expect(logs.first.metadata!['source'], equals('test'));
    });
  });
}
