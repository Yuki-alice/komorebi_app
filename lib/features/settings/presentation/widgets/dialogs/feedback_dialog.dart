import 'package:flutter/material.dart';
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
  
  FeedbackType _selectedType = FeedbackType.feedback;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
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

    final success = await _feedbackService.submitFeedback(
      type: _selectedType,
      content: content,
      contact: _contactController.text.trim().isEmpty 
          ? null 
          : _contactController.text.trim(),
    );

    setState(() => _isSubmitting = false);

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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
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
