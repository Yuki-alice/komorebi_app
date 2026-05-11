import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 应用更新下载服务
class UpdateDownloadService {
  static final UpdateDownloadService _instance = UpdateDownloadService._internal();
  factory UpdateDownloadService() => _instance;
  UpdateDownloadService._internal();

  Dio? _dio;
  bool _isDownloading = false;
  CancelToken? _cancelToken;

  bool get isDownloading => _isDownloading;

  /// 下载更新文件
  /// 
  /// [url] 下载链接
  /// [fileName] 文件名（如：komorebi_v1.0.0.apk）
  /// [onProgress] 进度回调 (received, total)
  /// [onSuccess] 下载成功回调，返回文件路径
  /// [onError] 下载失败回调
  /// [onCancelled] 取消下载回调
  Future<void> downloadUpdate({
    required String url,
    required String fileName,
    required void Function(int received, int total) onProgress,
    required void Function(String filePath) onSuccess,
    required void Function(String error) onError,
    required void Function() onCancelled,
  }) async {
    if (_isDownloading) {
      onError('已有下载任务在进行中');
      return;
    }

    _isDownloading = true;
    _cancelToken = CancelToken();

    try {
      _dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/updates/$fileName';

      // 确保目录存在
      final updateDir = Directory('${dir.path}/updates');
      if (!await updateDir.exists()) {
        await updateDir.create(recursive: true);
      }

      // Android 需要存储权限
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          onError('需要存储权限才能下载更新');
          _isDownloading = false;
          return;
        }
      }

      await _dio!.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received, total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (kDebugMode) {
        print('✅ 下载完成: $savePath');
      }

      onSuccess(savePath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (kDebugMode) {
          print('⏹️ 下载已取消');
        }
        onCancelled();
      } else {
        if (kDebugMode) {
          print('❌ 下载失败: ${e.message}');
        }
        onError('下载失败: ${e.message ?? '未知错误'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 下载异常: $e');
      }
      onError('下载异常: $e');
    } finally {
      _isDownloading = false;
      _cancelToken = null;
    }
  }

  /// 取消下载
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel();
    }
  }

  /// 安装 APK（Android）
  static Future<void> installApk(String filePath) async {
    if (Platform.isAndroid) {
      final result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        if (kDebugMode) {
          print('❌ APK 安装失败: ${result.message}');
        }
      }
    }
  }

  /// 打开安装包（Windows/macOS/Linux）
  static Future<void> openInstaller(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      if (kDebugMode) {
        print('❌ 打开安装包失败: ${result.message}');
      }
    }
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 从 URL 中提取文件名
  static String extractFileName(String url, {String defaultName = 'update'}) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last.isNotEmpty ? pathSegments.last : defaultName;
      }
      return defaultName;
    } catch (e) {
      return defaultName;
    }
  }
}
