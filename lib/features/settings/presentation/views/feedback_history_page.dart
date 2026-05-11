import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/support/feedback_service.dart';
import '../../../../utils/date_formatter.dart';
import '../widgets/dialogs/feedback_dialog.dart';

class FeedbackHistoryPage extends StatefulWidget {
  const FeedbackHistoryPage({super.key});

  @override
  State<FeedbackHistoryPage> createState() => _FeedbackHistoryPageState();
}

class _FeedbackHistoryPageState extends State<FeedbackHistoryPage> {
  final FeedbackService _feedbackService = FeedbackService();
  List<Map<String, dynamic>> _feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbackHistory();
  }

  Future<void> _loadFeedbackHistory() async {
    setState(() => _isLoading = true);
    final feedbacks = await _feedbackService.getUserFeedbackHistory(limit: 50);
    if (mounted) {
      setState(() {
        _feedbackList = feedbacks;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFeedbacks() async {
    await _loadFeedbackHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              '反馈与帮助',
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: false,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const FeedbackDialog(),
                ),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: '提交新反馈',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshFeedbacks,
                      child: _feedbackList.isEmpty
                          ? _buildEmptyState(theme)
                          : _buildFeedbackList(theme),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.feedback_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无反馈记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '提交您的第一个反馈，帮助我们做得更好',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const FeedbackDialog(),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('提交反馈'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _feedbackList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final feedback = _feedbackList[index];
        return _buildFeedbackCard(feedback, theme);
      },
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, ThemeData theme) {
    final type = feedback['type'] ?? 'other';
    final content = feedback['content'] ?? '';
    final status = feedback['status'] ?? 'pending';
    final adminReply = feedback['admin_reply'] as String?;
    final createdAt = feedback['created_at'] != null
        ? DateTime.parse(feedback['created_at'])
        : DateTime.now();
    final typeLabel = FeedbackType.values
        .firstWhere(
          (e) => e.name == type,
          orElse: () => FeedbackType.other,
        )
        .label;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：类型、时间、状态
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTypeIcon(type),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          DateFormatter.formatRelative(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status, theme),
                ],
              ),
              const SizedBox(height: 12),
              // 反馈内容
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              // 管理员回复（如果有）
              if (adminReply != null && adminReply.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildAdminReply(adminReply, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: 12,
            color: statusInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReply(String reply, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 16,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '管理员回复',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reply,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color, IconData icon}) _getStatusInfo(String status) {
    return switch (status) {
      'pending' => (
          label: '待处理',
          color: Colors.grey.shade600,
          icon: Icons.pending_outlined,
        ),
      'processing' => (
          label: '处理中',
          color: Colors.blue.shade600,
          icon: Icons.hourglass_empty,
        ),
      'resolved' => (
          label: '已解决',
          color: Colors.green.shade600,
          icon: Icons.check_circle_outline,
        ),
      'rejected' => (
          label: '已拒绝',
          color: Colors.red.shade600,
          icon: Icons.cancel_outlined,
        ),
      _ => (
          label: status,
          color: Colors.grey.shade600,
          icon: Icons.help_outline,
        ),
    };
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'feedback':
        return Icons.lightbulb_outline;
      case 'bug':
        return Icons.bug_report_outlined;
      case 'performance':
        return Icons.speed_outlined;
      case 'ui':
        return Icons.palette_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
