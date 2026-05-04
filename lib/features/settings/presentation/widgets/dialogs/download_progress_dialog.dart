import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../core/services/update_download_service.dart';

/// 下载进度对话框
class DownloadProgressDialog extends StatefulWidget {
  final String url;
  final String fileName;
  final VoidCallback onInstall;

  const DownloadProgressDialog({
    super.key,
    required this.url,
    required this.fileName,
    required this.onInstall,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  final _downloadService = UpdateDownloadService();
  double _progress = 0.0;
  int _received = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    await _downloadService.downloadUpdate(
      url: widget.url,
      fileName: widget.fileName,
      onProgress: (received, total) {
        if (mounted) {
          setState(() {
            _received = received;
            _total = total;
            _progress = total > 0 ? received / total : 0.0;
          });
        }
      },
      onSuccess: (filePath) {
        if (mounted) {
          setState(() {
            _progress = 1.0;
          });
          _showInstallDialog(filePath);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _error = error);
        }
      },
      onCancelled: () {
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  void _showInstallDialog(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('下载完成', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('安装包已下载完成，是否立即安装？'),
            const SizedBox(height: 8),
            Text(
              '文件大小: ${UpdateDownloadService.formatFileSize(_total)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('稍后安装'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onInstall();
              if (Platform.isAndroid) {
                UpdateDownloadService.installApk(filePath);
              } else {
                UpdateDownloadService.openInstaller(filePath);
              }
            },
            child: const Text('立即安装'),
          ),
        ],
      ),
    );
  }

  void _cancelDownload() {
    _downloadService.cancelDownload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error != null ? '下载失败' : '正在下载更新',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_error == null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelDownload,
                    tooltip: '取消下载',
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('关闭'),
                ),
              ),
            ] else ...[
              // 进度条
              LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              // 进度信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${UpdateDownloadService.formatFileSize(_received)} / ${UpdateDownloadService.formatFileSize(_total)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_downloadService.isDownloading) {
      _downloadService.cancelDownload();
    }
    super.dispose();
  }
}
