import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 帧率数据公共接口
abstract class FpsData {
  double get averageFps;
  double get minFps;
  double get maxFps;
  int get droppedFrames;
  int get totalFrames;
  double get dropRate;
}

/// 帧率录制会话结果
class FpsSessionResult implements FpsData {
  @override
  final double averageFps;
  @override
  final double minFps;
  @override
  final double maxFps;
  @override
  final int droppedFrames;
  @override
  final int totalFrames;
  @override
  final double dropRate;
  final Duration duration;
  final List<double> fpsHistory;

  FpsSessionResult({
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.droppedFrames,
    required this.totalFrames,
    required this.dropRate,
    required this.duration,
    required this.fpsHistory,
  });

  Map<String, dynamic> toJson() => {
    'averageFps': averageFps.toStringAsFixed(1),
    'minFps': minFps.toStringAsFixed(1),
    'maxFps': maxFps.toStringAsFixed(1),
    'droppedFrames': droppedFrames,
    'totalFrames': totalFrames,
    'dropRate': '${(dropRate * 100).toStringAsFixed(1)}%',
    'durationMs': duration.inMilliseconds,
  };
}

/// 帧率统计信息
class FpsStats implements FpsData {
  final double currentFps;
  @override
  final double averageFps;
  @override
  final double minFps;
  @override
  final double maxFps;
  @override
  final int droppedFrames;
  @override
  final int totalFrames;
  @override
  final double dropRate;

  FpsStats({
    required this.currentFps,
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.droppedFrames,
    required this.totalFrames,
    required this.dropRate,
  });

  Map<String, dynamic> toJson() => {
    'currentFps': currentFps.toStringAsFixed(1),
    'averageFps': averageFps.toStringAsFixed(1),
    'minFps': minFps.toStringAsFixed(1),
    'maxFps': maxFps.toStringAsFixed(1),
    'droppedFrames': droppedFrames,
    'totalFrames': totalFrames,
    'dropRate': '${(dropRate * 100).toStringAsFixed(1)}%',
  };
}

/// FPS 监控器
///
/// 通过 SchedulerBinding 监听帧回调，计算实时帧率。
/// 仅在 Debug 模式下启用，Release 模式下自动禁用。
///
/// 使用方式：
/// ```dart
/// final fps = FpsMonitor();
/// fps.startRecording();  // 开始录制
/// // ... 执行需要测试的操作 ...
/// fps.stopRecording();   // 停止录制
/// final result = fps.getSessionResult(); // 获取录制结果
/// ```
class FpsMonitor {
  static final FpsMonitor _instance = FpsMonitor._internal();
  factory FpsMonitor() => _instance;
  FpsMonitor._internal();

  Ticker? _ticker;
  bool _isRunning = false;

  // 帧时间记录（毫秒）
  final Queue<double> _frameTimes = Queue();
  static const int _maxFrameHistory = 300; // 保留最多 300 帧（约 5 秒 @ 60fps）

  // 统计信息
  int _totalFrames = 0;
  int _droppedFrames = 0;
  double _minFps = double.infinity;
  double _maxFps = 0;
  double _currentFps = 0;

  // 录制会话相关
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  int _recordedFramesAtStart = 0;
  int _recordedDroppedAtStart = 0;

  // 目标帧率（默认 60fps）
  static const double _targetFrameTimeMs = 1000.0 / 60.0;

  /// 是否正在监控
  bool get isRunning => _isRunning;

  /// 是否正在录制会话
  bool get isRecording => _isRecording;

  /// 当前 FPS
  double get currentFps => _currentFps;

  /// 启动监控（全局帧率跟踪）
  void start() {
    if (_isRunning || !kDebugMode) return;

    _isRunning = true;
    _ticker = Ticker(_onTick);
    _ticker!.start();
  }

  /// 停止监控
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  /// 重置所有数据
  void reset() {
    _frameTimes.clear();
    _totalFrames = 0;
    _droppedFrames = 0;
    _minFps = double.infinity;
    _maxFps = 0;
    _currentFps = 0;
    _isRecording = false;
    _recordingStartTime = null;
    _recordedFramesAtStart = 0;
    _recordedDroppedAtStart = 0;
  }

  /// 开始录制会话
  ///
  /// 会重置之前的录制数据，开始新的录制会话。
  /// 录制期间可以执行需要测试性能的操作。
  void startRecording() {
    if (!kDebugMode) return;

    // 确保监控已启动
    if (!_isRunning) {
      start();
    }

    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _recordedFramesAtStart = _totalFrames;
    _recordedDroppedAtStart = _droppedFrames;
  }

  /// 停止录制会话
  void stopRecording() {
    _isRecording = false;
  }

  /// 获取当前录制会话的结果
  ///
  /// 如果未在录制中，返回 null。
  FpsSessionResult? getSessionResult() {
    if (_recordingStartTime == null) return null;

    final duration = DateTime.now().difference(_recordingStartTime!);
    final sessionTotalFrames = _totalFrames - _recordedFramesAtStart;
    final sessionDroppedFrames = _droppedFrames - _recordedDroppedAtStart;

    if (sessionTotalFrames <= 0) return null;

    // 计算会话期间的平均 FPS
    double avgFps = 0;
    if (_frameTimes.length >= 2) {
      final times = _frameTimes.toList();
      // 只取录制期间的数据
      final startIndex = times.length > sessionTotalFrames
          ? times.length - sessionTotalFrames
          : 0;

      if (times.length > startIndex + 1) {
        final first = times[startIndex];
        final last = times.last;
        final frameDuration = last - first;
        if (frameDuration > 0) {
          avgFps = (times.length - startIndex - 1) * 1000.0 / frameDuration;
        }
      }
    }

    // 计算会话期间的 min/max FPS
    double minFps = double.infinity;
    double maxFps = 0;
    final fpsHistory = getFpsHistory(count: sessionTotalFrames);
    for (final fps in fpsHistory) {
      if (fps > 0 && fps < minFps) minFps = fps;
      if (fps > maxFps) maxFps = fps;
    }
    if (minFps == double.infinity) minFps = 0;

    final dropRate = sessionTotalFrames > 0
        ? (sessionDroppedFrames / sessionTotalFrames).toDouble()
        : 0.0;

    return FpsSessionResult(
      averageFps: avgFps,
      minFps: minFps,
      maxFps: maxFps,
      droppedFrames: sessionDroppedFrames,
      totalFrames: sessionTotalFrames,
      dropRate: dropRate,
      duration: duration,
      fpsHistory: fpsHistory,
    );
  }

  void _onTick(Duration elapsed) {
    if (!_isRunning) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _totalFrames++;

    // 计算帧间隔
    if (_frameTimes.isNotEmpty) {
      final lastTime = _frameTimes.last;
      final frameTime = now - lastTime;

      // 掉帧检测：帧时间超过目标帧时间的 1.5 倍视为掉帧
      if (frameTime > _targetFrameTimeMs * 1.5) {
        _droppedFrames++;
      }

      // 计算当前 FPS（基于最近几帧的平均）
      _calculateFps();
    }

    _frameTimes.add(now.toDouble());

    // 限制历史记录长度
    while (_frameTimes.length > _maxFrameHistory) {
      _frameTimes.removeFirst();
    }
  }

  void _calculateFps() {
    if (_frameTimes.length < 2) return;

    final times = _frameTimes.toList();
    final recentFrames = times.sublist(times.length > 10 ? times.length - 10 : 0);

    if (recentFrames.length < 2) return;

    double totalTime = 0;
    for (int i = 1; i < recentFrames.length; i++) {
      totalTime += recentFrames[i] - recentFrames[i - 1];
    }

    final avgFrameTime = totalTime / (recentFrames.length - 1);
    if (avgFrameTime > 0) {
      _currentFps = 1000.0 / avgFrameTime;

      if (_currentFps > _maxFps) _maxFps = _currentFps;
      if (_currentFps < _minFps && _currentFps > 0) _minFps = _currentFps;
    }
  }

  /// 获取统计信息（全局累计数据）
  FpsStats getStats() {
    if (_frameTimes.isEmpty || _totalFrames == 0) {
      return FpsStats(
        currentFps: 0,
        averageFps: 0,
        minFps: 0,
        maxFps: 0,
        droppedFrames: 0,
        totalFrames: 0,
        dropRate: 0,
      );
    }

    // 计算平均 FPS
    double avgFps = 0;
    if (_frameTimes.length >= 2) {
      final first = _frameTimes.first;
      final last = _frameTimes.last;
      final duration = last - first;
      if (duration > 0) {
        avgFps = (_frameTimes.length - 1) * 1000.0 / duration;
      }
    }

    final dropRate = _totalFrames > 0
        ? (_droppedFrames / _totalFrames).toDouble()
        : 0.0;

    return FpsStats(
      currentFps: _currentFps,
      averageFps: avgFps,
      minFps: _minFps == double.infinity ? 0.0 : _minFps,
      maxFps: _maxFps,
      droppedFrames: _droppedFrames,
      totalFrames: _totalFrames,
      dropRate: dropRate,
    );
  }

  /// 获取最近帧率历史（用于图表）
  List<double> getFpsHistory({int count = 60}) {
    if (_frameTimes.length < 2) return [];

    final times = _frameTimes.toList();
    final List<double> fpsList = [];

    final startIndex = times.length > count ? times.length - count : 1;

    for (int i = startIndex; i < times.length; i++) {
      final frameTime = times[i] - times[i - 1];
      if (frameTime > 0) {
        fpsList.add(1000.0 / frameTime);
      }
    }

    return fpsList;
  }
}
