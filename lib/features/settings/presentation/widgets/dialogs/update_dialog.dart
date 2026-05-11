import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/services/support/feedback_service.dart';
import '../../../../../core/services/support/update_download_service.dart';
import 'download_progress_dialog.dart';

/// 应用更新对话框
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  /// 处理下载更新
  void _handleDownload(BuildContext context) {
    if (updateInfo.downloadUrl == null || updateInfo.downloadUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无下载链接，请稍后重试')),
      );
      return;
    }

    // 显示下载进度对话框
    final fileName = UpdateDownloadService.extractFileName(
      updateInfo.downloadUrl!,
      defaultName: _getDefaultFileName(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DownloadProgressDialog(
        url: updateInfo.downloadUrl!,
        fileName: fileName,
        onInstall: () {
          // 安装完成后的回调（如果需要可以添加额外逻辑）
        },
      ),
    );
  }

  /// 获取默认文件名
  String _getDefaultFileName() {
    if (Platform.isAndroid) return 'komorebi_${updateInfo.version}.apk';
    if (Platform.isWindows) return 'komorebi_${updateInfo.version}.exe';
    if (Platform.isMacOS) return 'komorebi_${updateInfo.version}.dmg';
    if (Platform.isLinux) return 'komorebi_${updateInfo.version}.AppImage';
    return 'komorebi_${updateInfo.version}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promptLevel = updateInfo.promptLevel;

    // 根据提示级别选择图标和颜色
    IconData icon;
    Color iconColor;
    String title;
    
    switch (promptLevel) {
      case UpdatePromptLevel.strong:
        icon = Icons.system_update;
        iconColor = Colors.orange.shade600;
        title = '重要更新';
        break;
      case UpdatePromptLevel.moderate:
        icon = Icons.system_update_alt;
        iconColor = theme.colorScheme.primary;
        title = '发现新版本';
        break;
      case UpdatePromptLevel.gentle:
        icon = Icons.new_releases;
        iconColor = Colors.green.shade600;
        title = '有新版本可用';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          updateInfo.formattedVersion,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 版本差距提示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '当前版本落后 ${updateInfo.versionGap} 个版本',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 更新标题
              Text(
                updateInfo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // 更新日志（支持分类标题和列表）
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: _buildChangelog(updateInfo.description, theme),
                ),
              ),
              const SizedBox(height: 8),

              // 发布日期
              Text(
                '发布日期: ${_formatDate(updateInfo.releaseDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // 按钮区域
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('稍后更新'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _handleDownload(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _getDownloadButtonText(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 下载提示
              if (_getDownloadHint() != null) ...[
                const SizedBox(height: 8),
                Text(
                  _getDownloadHint()!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建更新日志（支持分类标题和列表）
  /// 
  /// 支持的格式：
  /// ## 标题（如：## 新增功能）
  /// - 列表项
  /// • 列表项
  /// 普通文本
  Widget _buildChangelog(String content, ThemeData theme) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('## ')) {
        // 分类标题
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              trimmed.substring(3).trim(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
        // 列表项
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trimmed.substring(2).trim(),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // 普通文本
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 获取下载按钮文案
  String _getDownloadButtonText() {
    if (Platform.isAndroid) return '下载 APK';
    if (Platform.isIOS) return '前往 App Store';
    if (Platform.isWindows) return '下载安装包';
    if (Platform.isMacOS) return '下载 DMG';
    if (Platform.isLinux) return '下载 Linux 版';
    return '去更新';
  }

  /// 获取下载提示文案
  String? _getDownloadHint() {
    if (Platform.isAndroid) return '下载完成后自动提示安装';
    if (Platform.isIOS) return '跳转至 App Store 更新';
    if (Platform.isWindows) return '下载后运行安装程序';
    if (Platform.isMacOS) return '下载后拖入 Applications';
    if (Platform.isLinux) return '根据您的发行版选择合适的安装包';
    return null;
  }
}

/// 已是最新版本对话框
class NoUpdateDialog extends StatelessWidget {
  final String currentVersion;

  const NoUpdateDialog({
    super.key,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '已是最新版本',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '当前版本 $currentVersion',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('知道了'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
