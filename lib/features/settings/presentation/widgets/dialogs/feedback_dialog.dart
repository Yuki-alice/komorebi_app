import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/services/feedback_service.dart';
import '../../../../../utils/toast_utils.dart';

/// 用户反馈对话框
class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  FeedbackType _selectedType = FeedbackType.feedback;
  bool _isSubmitting = false;
  String? _screenshotPath;
  bool _isUploading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _screenshotPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '选择图片失败');
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _screenshotPath = null;
    });
  }

  Future<String?> _uploadImage() async {
    if (_screenshotPath == null) return null;

    setState(() => _isUploading = true);

    try {
      // 压缩图片
      final compressedFile = await _compressImage(_screenshotPath!);
      
      // 上传到 Supabase
      final url = await _feedbackService.uploadScreenshot(compressedFile!);
      
      return url;
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '上传图片失败');
      }
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _compressImage(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      return result?.path;
    } catch (e) {
      // 如果压缩失败，返回原路径
      return path;
    }
  }

  Future<void> _submitFeedback() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      if (mounted) {
        ToastUtils.showError(context, '请输入反馈内容');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 如果有截图，先上传
      String? screenshotUrl;
      if (_screenshotPath != null) {
        screenshotUrl = await _uploadImage();
      }

      final success = await _feedbackService.submitFeedback(
        type: _selectedType,
        content: content,
        contact: _contactController.text.trim().isEmpty 
            ? null 
            : _contactController.text.trim(),
        screenshot: screenshotUrl,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ToastUtils.showSuccess(context, '感谢您的反馈，我们会尽快处理！');
        }
      } else {
        if (mounted) {
          ToastUtils.showError(context, '提交失败，请稍后重试');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.feedback_outlined,
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
                          '意见反馈',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '帮助我们做得更好',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 可滚动内容区域
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 反馈类型选择
                      Text(
                        '反馈类型',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: FeedbackType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            label: Text(type.label),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedType = type),
                            selectedColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected 
                                  ? theme.colorScheme.onPrimaryContainer 
                                  : theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 反馈内容
                      Text(
                        '详细描述',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentController,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: '请详细描述您的问题或建议...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 截图上传（可选）
                      Text(
                        '添加截图（可选）',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _screenshotPath == null ? _pickImage : null,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: _screenshotPath != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_screenshotPath!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: _removeImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '点击添加截图',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 联系方式（可选）
                      Text(
                        '联系方式（可选）',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contactController,
                        decoration: InputDecoration(
                          hintText: '邮箱或手机号，方便我们联系您',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.contact_mail_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_isSubmitting || _isUploading) ? null : _submitFeedback,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting || _isUploading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploading ? '上传截图中...' : '提交中...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          '提交反馈',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
