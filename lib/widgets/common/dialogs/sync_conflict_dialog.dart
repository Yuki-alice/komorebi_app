import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🌟 同步冲突解决对话框
/// 
/// 当本地和云端笔记都有更新时，提示用户选择保留哪个版本
class SyncConflictDialog extends StatelessWidget {
  final String noteTitle;
  final int localVersion;
  final int cloudVersion;
  final DateTime localUpdatedAt;
  final DateTime cloudUpdatedAt;

  const SyncConflictDialog({
    super.key,
    required this.noteTitle,
    required this.localVersion,
    required this.cloudVersion,
    required this.localUpdatedAt,
    required this.cloudUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.sync_problem_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '同步冲突',
              style: GoogleFonts.notoSansSc(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '笔记 "$noteTitle" 在本地和云端都有更新：',
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          
          // 本地版本
          _buildVersionCard(
            context: context,
            label: '本地版本',
            version: localVersion,
            updatedAt: localUpdatedAt,
            icon: Icons.devices_rounded,
            color: colorScheme.primary,
          ),
          
          const SizedBox(height: 12),
          
          // 云端版本
          _buildVersionCard(
            context: context,
            label: '云端版本',
            version: cloudVersion,
            updatedAt: cloudUpdatedAt,
            icon: Icons.cloud_rounded,
            color: colorScheme.tertiary,
          ),
          
          const SizedBox(height: 16),
          
          // 提示信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '选择保留的版本将覆盖另一个版本，此操作不可撤销。',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            '稍后处理',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, 'cloud'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.tertiaryContainer,
            foregroundColor: colorScheme.onTertiaryContainer,
          ),
          child: const Text('保留云端'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'local'),
          child: const Text('保留本地'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  Widget _buildVersionCard({
    required BuildContext context,
    required String label,
    required int version,
    required DateTime updatedAt,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '版本 $version · ${_formatDate(updatedAt)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    
    return '${date.month}月${date.day}日';
  }
}

/// 🌟 显示同步冲突对话框
/// 
/// 返回：
/// - 'local': 保留本地版本
/// - 'cloud': 保留云端版本
/// - null: 用户取消
Future<String?> showSyncConflictDialog({
  required BuildContext context,
  required String noteTitle,
  required int localVersion,
  required int cloudVersion,
  required DateTime localUpdatedAt,
  required DateTime cloudUpdatedAt,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SyncConflictDialog(
      noteTitle: noteTitle,
      localVersion: localVersion,
      cloudVersion: cloudVersion,
      localUpdatedAt: localUpdatedAt,
      cloudUpdatedAt: cloudUpdatedAt,
    ),
  );
}
