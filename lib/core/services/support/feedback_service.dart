import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 用户反馈服务
/// 
/// 负责收集用户反馈、崩溃报告和应用更新检查
class FeedbackService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// 上传截图到 Supabase Storage
  /// 
  /// [imagePath] 本地图片路径
  /// 返回上传后的图片 URL
  Future<String?> uploadScreenshot(String imagePath) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('⚠️ 用户未登录，无法上传截图');
        }
        return null;
      }

      // 从完整路径中提取文件名并转换为安全格式
      final originalFileName = imagePath.split(Platform.pathSeparator).last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // 只保留字母、数字、点号和下划线，替换其他字符
      final safeFileName = originalFileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final filePath = '${user.id}/${timestamp}_$safeFileName';

      if (kDebugMode) {
        print('📤 开始上传截图:');
        print('   用户ID: ${user.id}');
        print('   原始路径: $imagePath');
        print('   原始文件名: $originalFileName');
        print('   安全文件名: $safeFileName');
        print('   存储路径: $filePath');
      }

      // 检查文件是否存在
      final file = File(imagePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          print('❌ 文件不存在: $imagePath');
        }
        return null;
      }

      final fileSize = await file.length();
      if (kDebugMode) {
        print('   文件大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }

      await _supabase.storage
          .from('feedback-screenshots')
          .upload(filePath, file);

      final publicUrl = _supabase.storage
          .from('feedback-screenshots')
          .getPublicUrl(filePath);

      if (kDebugMode) {
        print('✅ 截图上传成功: $publicUrl');
      }
      return publicUrl;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ 截图上传失败: $e');
        print('   堆栈跟踪: $stackTrace');
      }
      return null;
    }
  }

  /// 提交用户反馈
  /// 
  /// [type] 反馈类型：feedback(功能建议), bug(问题反馈), other(其他)
  /// [content] 反馈内容
  /// [contact] 联系方式（可选）
  /// [screenshot] 截图 URL（可选）
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

  /// 获取用户的反馈历史
  /// 
  /// [limit] 限制数量，默认 20
  /// 返回反馈列表
  Future<List<Map<String, dynamic>>> getUserFeedbackHistory({int limit = 20}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('⚠️ 用户未登录，无法获取反馈历史');
        }
        return [];
      }

      final response = await _supabase
          .from('user_feedback')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      if (kDebugMode) {
        print('✅ 获取反馈历史成功，共 ${response.length} 条');
      }
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ 获取反馈历史失败: $e');
      }
      return [];
    }
  }

  /// 检查是否有新的管理员回复
  /// 
  /// [feedbackId] 反馈 ID
  /// 返回管理员回复内容，如果没有回复返回 null
  Future<String?> checkAdminReply(String feedbackId) async {
    try {
      final response = await _supabase
          .from('user_feedback')
          .select('admin_reply, status')
          .eq('id', feedbackId)
          .maybeSingle();

      if (response != null) {
        return response['admin_reply'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 检查管理员回复失败: $e');
      }
      return null;
    }
  }

  /// 检查应用更新
  /// 
  /// 返回更新信息，如果没有更新返回 null
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 使用 API 检查更新（带频率控制）
      final shouldCheck = await _shouldCheckForUpdate();
      if (!shouldCheck) {
        if (kDebugMode) {
          print('⏭️ 跳过更新检查（距离上次检查不足 24 小时）');
        }
        return null;
      }

      final response = await _supabase
          .rpc('check_app_update', params: {
            'p_platform': _getPlatform(),
            'p_build_number': currentBuild,
          });

      if (response == null) return null;

      final hasUpdate = response['hasUpdate'] as bool? ?? false;
      if (!hasUpdate) {
        // 记录检查时间
        await _recordLastCheckTime();
        return null;
      }

      final updateInfo = response['updateInfo'];
      if (updateInfo == null) return null;

      final latestBuild = updateInfo['buildNumber'] as int;
      final versionGap = latestBuild - currentBuild;

      // 记录检查时间
      await _recordLastCheckTime();

      return UpdateInfo(
        version: updateInfo['version'] as String,
        buildNumber: latestBuild,
        title: updateInfo['title'] ?? '新版本可用',
        description: updateInfo['description'] ?? '',
        downloadUrl: updateInfo['downloadUrl'],
        releaseDate: DateTime.parse(updateInfo['releaseDate']),
        versionGap: versionGap > 0 ? versionGap : 1,
      );
    } catch (e) {
      if (kDebugMode) {
        print(' 检查更新失败: $e');
      }
      return null;
    }
  }

  /// 检查是否应该进行更新检查（频率控制：24 小时内只检查一次）
  Future<bool> _shouldCheckForUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_lastUpdateCheckKey);
      
      if (lastCheckStr == null) return true;
      
      final lastCheck = DateTime.parse(lastCheckStr);
      final now = DateTime.now();
      final hoursSinceLastCheck = now.difference(lastCheck).inHours;
      
      return hoursSinceLastCheck >= 24; // 24 小时检查间隔
    } catch (e) {
      return true; // 出错时允许检查
    }
  }

  /// 记录上次更新检查时间
  Future<void> _recordLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUpdateCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      // 忽略记录失败
    }
  }

  static const String _lastUpdateCheckKey = 'last_update_check_time';

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
  final DateTime releaseDate;
  final int versionGap; // 版本差距（相差几个版本）

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.title,
    required this.description,
    this.downloadUrl,
    required this.releaseDate,
    this.versionGap = 1,
  });

  String get formattedVersion => '$version (Build $buildNumber)';
  
  /// 获取提示级别
  UpdatePromptLevel get promptLevel {
    if (versionGap >= 5) return UpdatePromptLevel.strong;
    if (versionGap >= 3) return UpdatePromptLevel.moderate;
    return UpdatePromptLevel.gentle;
  }
}

/// 更新提示级别
enum UpdatePromptLevel {
  gentle,   // 温和提示（相差 1-2 个版本）
  moderate, // 中等提示（相差 3-4 个版本）
  strong,   // 强烈提示（相差 5+ 个版本）
}

/// 更新状态
class UpdateStatus {
  final bool hasUpdate;
  final UpdateInfo? updateInfo;
  final DateTime? lastCheckTime;

  UpdateStatus({
    required this.hasUpdate,
    this.updateInfo,
    this.lastCheckTime,
  });
}
