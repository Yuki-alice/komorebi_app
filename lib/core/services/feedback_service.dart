import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 用户反馈服务
/// 
/// 负责收集用户反馈、崩溃报告和应用更新检查
class FeedbackService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// 提交用户反馈
  /// 
  /// [type] 反馈类型：feedback(功能建议), bug(问题反馈), other(其他)
  /// [content] 反馈内容
  /// [contact] 联系方式（可选）
  /// [screenshot] 截图路径（可选）
  Future<bool> submitFeedback({
    required FeedbackType type,
    required String content,
    String? contact,
    String? screenshot,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final deviceInfo = await _getDeviceInfo();
      final appInfo = await _getAppInfo();

      await _supabase.from('user_feedback').insert({
        'user_id': user?.id,
        'type': type.name,
        'content': content,
        'contact': contact,
        'screenshot': screenshot,
        'device_info': deviceInfo,
        'app_info': appInfo,
        'status': 'pending',
      });

      if (kDebugMode) {
        print('✅ 反馈提交成功: ${type.name}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 反馈提交失败: $e');
      }
      return false;
    }
  }

  /// 检查应用更新
  /// 
  /// 返回更新信息，如果没有更新返回 null
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 从数据库获取最新版本信息
      final response = await _supabase
          .from('app_updates')
          .select()
          .eq('platform', _getPlatform())
          .eq('is_active', true)
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final latestBuild = response['build_number'] as int;
      final latestVersion = response['version'] as String;

      if (latestBuild > currentBuild) {
        return UpdateInfo(
          version: latestVersion,
          buildNumber: latestBuild,
          title: response['title'] ?? '新版本可用',
          description: response['description'] ?? '',
          downloadUrl: response['download_url'],
          isForceUpdate: response['is_force_update'] ?? false,
          releaseDate: DateTime.parse(response['release_date']),
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 检查更新失败: $e');
      }
      return null;
    }
  }

  /// 获取设备信息
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final info = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info['platform'] = 'Android';
        info['model'] = androidInfo.model;
        info['brand'] = androidInfo.brand;
        info['version'] = androidInfo.version.release;
        info['sdk'] = androidInfo.version.sdkInt;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info['platform'] = 'iOS';
        info['model'] = iosInfo.model;
        info['systemVersion'] = iosInfo.systemVersion;
        info['name'] = iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        info['platform'] = 'Windows';
        info['computerName'] = windowsInfo.computerName;
        info['numberOfCores'] = windowsInfo.numberOfCores;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        info['platform'] = 'macOS';
        info['model'] = macInfo.model;
        info['osRelease'] = macInfo.osRelease;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        info['platform'] = 'Linux';
        info['name'] = linuxInfo.name;
        info['version'] = linuxInfo.version;
      }
    } catch (e) {
      info['platform'] = 'Unknown';
      info['error'] = e.toString();
    }

    return info;
  }

  /// 获取应用信息
  Future<Map<String, dynamic>> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
    };
  }

  /// 获取当前平台标识
  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}

/// 反馈类型
enum FeedbackType {
  feedback('功能建议'),
  bug('问题反馈'),
  performance('性能问题'),
  ui('界面问题'),
  other('其他');

  final String label;
  const FeedbackType(this.label);
}

/// 更新信息
class UpdateInfo {
  final String version;
  final int buildNumber;
  final String title;
  final String description;
  final String? downloadUrl;
  final bool isForceUpdate;
  final DateTime releaseDate;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.title,
    required this.description,
    this.downloadUrl,
    required this.isForceUpdate,
    required this.releaseDate,
  });

  String get formattedVersion => '$version (Build $buildNumber)';
}
