import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// 🌟 数据迁移服务
/// 
/// 处理从旧应用名 (notesync_app) 到新应用名 (komorebi) 的数据迁移
/// 支持 Android 和 Windows 平台
class DataMigrationService {
  static const String _migrationCompletedKey = 'data_migration_completed_v1';
  
  // Android 包名
  static const String _oldAndroidPackage = 'com.example.notesync_app';
  static const String _newAndroidPackage = 'app.komorebi';
  
  // Windows 应用名
  static const String _oldWindowsAppName = 'notesync_app';
  static const String _newWindowsAppName = 'komorebi';

  /// 检查是否需要迁移
  static Future<bool> needsMigration() async {
    // 只在 Android 和 Windows 平台检查
    if (!Platform.isAndroid && !Platform.isWindows) return false;

    final prefs = await SharedPreferences.getInstance();
    
    // 已经迁移过，不需要再次迁移
    if (prefs.getBool(_migrationCompletedKey) == true) {
      return false;
    }

    // 检查旧应用的数据目录是否存在
    final oldDataPath = await _getOldAppDataPath();
    if (oldDataPath == null) return false;

    final oldDbFile = File(p.join(oldDataPath, 'default.isar'));
    return await oldDbFile.exists();
  }

  /// 执行数据迁移
  static Future<MigrationResult> migrate() async {
    try {
      debugPrint('🔄 开始数据迁移...');

      // 1. 获取旧应用数据路径
      final oldDataPath = await _getOldAppDataPath();
      if (oldDataPath == null) {
        return MigrationResult(
          success: false,
          message: '找不到旧应用数据目录',
        );
      }

      // 2. 获取新应用数据路径
      final newAppDir = await getApplicationDocumentsDirectory();
      final newDataPath = newAppDir.path;

      // 3. 迁移 Isar 数据库
      await _migrateDatabase(oldDataPath, newDataPath);

      // 4. 迁移图片文件
      await _migrateImages(oldDataPath, newDataPath);

      // 5. 迁移 SharedPreferences
      await _migratePreferences(oldDataPath);

      // 6. 标记迁移完成
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationCompletedKey, true);

      debugPrint('✅ 数据迁移完成！');
      return MigrationResult(
        success: true,
        message: '数据迁移成功',
      );
    } catch (e, stackTrace) {
      debugPrint('🚨 数据迁移失败: $e');
      debugPrint(stackTrace.toString());
      return MigrationResult(
        success: false,
        message: '迁移失败: $e',
      );
    }
  }

  /// 获取旧应用数据路径
  static Future<String?> _getOldAppDataPath() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidOldDataPath();
      } else if (Platform.isWindows) {
        return await _getWindowsOldDataPath();
      }
      return null;
    } catch (e) {
      debugPrint('获取旧数据路径失败: $e');
      return null;
    }
  }

  /// 获取 Android 旧数据路径
  static Future<String?> _getAndroidOldDataPath() async {
    // Android 应用数据存储在 /data/data/{packageName}/
    final possiblePaths = [
      '/data/data/$_oldAndroidPackage/app_flutter',
      '/data/user/0/$_oldAndroidPackage/app_flutter',
      '/sdcard/Android/data/$_oldAndroidPackage/files',
    ];

    for (final path in possiblePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        debugPrint('📁 找到 Android 旧应用数据目录: $path');
        return path;
      }
    }

    // 尝试通过 shell 命令获取（需要 root）
    try {
      final result = await Process.run('ls', ['/data/data/$_oldAndroidPackage/']);
      if (result.exitCode == 0) {
        return '/data/data/$_oldAndroidPackage/app_flutter';
      }
    } catch (_) {
      // 忽略权限错误
    }

    return null;
  }

  /// 获取 Windows 旧数据路径
  static Future<String?> _getWindowsOldDataPath() async {
    // Windows 应用数据存储在 %APPDATA%/{app_name}/
    final appData = Platform.environment['APPDATA'];
    if (appData == null) return null;

    // 可能的旧数据路径
    final possiblePaths = [
      p.join(appData, _oldWindowsAppName),
      p.join(appData, 'com.example', _oldWindowsAppName),
      p.join(appData, 'Flutter', _oldWindowsAppName),
    ];

    for (final path in possiblePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        debugPrint('📁 找到 Windows 旧应用数据目录: $path');
        return path;
      }
    }

    // 检查当前目录的上一级是否有旧版本（开发环境）
    final currentDir = Directory.current;
    final parentDir = currentDir.parent;
    final siblingOldDir = Directory(p.join(parentDir.path, _oldWindowsAppName));
    if (await siblingOldDir.exists()) {
      debugPrint('📁 找到 Windows 旧应用数据目录(同级): ${siblingOldDir.path}');
      return siblingOldDir.path;
    }

    return null;
  }

  /// 迁移数据库文件
  static Future<void> _migrateDatabase(String oldPath, String newPath) async {
    final oldDbDir = Directory(oldPath);
    if (!await oldDbDir.exists()) return;

    // 复制所有 .isar 文件
    final List<File> dbFiles = [];
    await for (final entity in oldDbDir.list()) {
      if (entity is File && entity.path.endsWith('.isar')) {
        dbFiles.add(entity);
      }
    }

    for (final file in dbFiles) {
      final fileName = p.basename(file.path);
      final newFilePath = p.join(newPath, fileName);
      
      // 如果新位置已存在，先备份
      final newFile = File(newFilePath);
      if (await newFile.exists()) {
        final backupPath = '$newFilePath.backup.${DateTime.now().millisecondsSinceEpoch}';
        await newFile.rename(backupPath);
      }

      await file.copy(newFilePath);
      debugPrint('📦 已迁移数据库: $fileName');
    }
  }

  /// 迁移图片文件
  static Future<void> _migrateImages(String oldPath, String newPath) async {
    final oldImageDir = Directory(p.join(oldPath, 'note_images'));
    if (!await oldImageDir.exists()) return;

    final newImageDir = Directory(p.join(newPath, 'note_images'));
    if (!await newImageDir.exists()) {
      await newImageDir.create(recursive: true);
    }

    final List<File> images = [];
    await for (final entity in oldImageDir.list()) {
      if (entity is File) {
        images.add(entity);
      }
    }
    
    for (final image in images) {
      final fileName = p.basename(image.path);
      final newImagePath = p.join(newImageDir.path, fileName);
      await image.copy(newImagePath);
    }

    debugPrint('🖼️ 已迁移 ${images.length} 张图片');
  }

  /// 迁移 SharedPreferences
  static Future<void> _migratePreferences(String oldPath) async {
    // SharedPreferences 在 Android 上以 XML 文件存储
    final oldPrefsPath = p.join(oldPath, '../shared_prefs');
    final oldPrefsDir = Directory(oldPrefsPath);
    
    if (!await oldPrefsDir.exists()) return;

    final newPrefs = await SharedPreferences.getInstance();
    
    // 读取旧 prefs 文件并迁移关键设置
    // 注意：直接读取 XML 比较复杂，这里采用应用内引导用户重新设置的方式
    // 或者使用 content provider 在旧应用中暴露数据

    // 标记需要用户确认的设置项
    await newPrefs.setBool('_needs_settings_review', true);
    debugPrint('⚙️ SharedPreferences 需要用户重新确认');
  }

  /// 显示迁移提示对话框
  static Future<void> showMigrationDialog(BuildContext context) async {
    final isWindows = Platform.isWindows;
    final oldAppName = isWindows ? 'NoteSync (Windows)' : 'NoteSync';
    final dataLocation = isWindows
        ? '数据位于 %APPDATA%\\notesync_app'
        : '数据位于应用私有目录';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.system_update_alt, color: Theme.of(context).colorScheme.primary, size: 48),
        title: const Text('数据迁移'),
        content: Text(
          '检测到旧版本 "$oldAppName" 的数据。\n\n'
          '$dataLocation\n\n'
          '是否将数据迁移到新版本 "Komorebi"？\n\n'
          '迁移内容包括：\n'
          '• 所有笔记和待办事项\n'
          '• 分类和标签\n'
          '• 本地图片\n\n'
          '注意：迁移完成后，旧版本应用的数据仍会保留。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('跳过'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performMigrationWithLoading(context);
            },
            child: const Text('开始迁移'),
          ),
        ],
      ),
    );
  }

  /// 执行迁移并显示加载状态
  static Future<void> _performMigrationWithLoading(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在迁移数据，请稍候...'),
            ],
          ),
        ),
      ),
    );

    final result = await migrate();

    // 关闭加载对话框
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // 显示结果
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: result.success ? Colors.green : Colors.red,
            size: 48,
          ),
          title: Text(result.success ? '迁移成功' : '迁移失败'),
          content: Text(result.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}

/// 迁移结果
class MigrationResult {
  final bool success;
  final String message;

  const MigrationResult({
    required this.success,
    required this.message,
  });
}
