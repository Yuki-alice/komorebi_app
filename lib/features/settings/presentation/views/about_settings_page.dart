import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/feedback_service.dart';
import '../widgets/dialogs/feedback_dialog.dart';
import '../widgets/dialogs/update_dialog.dart';
import 'feedback_history_page.dart';

class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({super.key});

  @override
  State<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  final FeedbackService _feedbackService = FeedbackService();
  bool _isCheckingUpdate = false;
  String _version = '加载中...';
  UpdateInfo? _pendingUpdate; // 待显示的更新信息

  // 隐私政策内容
  static const String _privacyPolicyContent = '''
隐私政策

最后更新日期：2026年4月

1. 信息收集
Komorebi 是一款注重隐私的笔记应用。我们收集的信息包括：
• 账户信息：邮箱地址（用于登录和同步）
• 设备信息：设备型号、操作系统版本（用于优化体验）
• 使用数据：崩溃报告、性能数据（用于改进应用）

2. 数据存储
• 本地笔记：存储在您的设备上，完全由您控制
• 云端同步：使用 Supabase 服务，数据加密传输和存储
• 我们不会将您的笔记内容用于任何商业目的

3. 数据安全
• 所有云端数据传输使用 TLS 加密
• 敏感操作需要身份验证
• 您可以随时导出或删除您的数据

4. 第三方服务
我们使用以下第三方服务：
• Supabase：提供云端同步和身份验证
• 这些服务仅用于实现核心功能

5. 您的权利
• 访问、修改或删除您的个人数据
• 随时注销账户
• 导出您的所有数据

如有疑问，请通过反馈功能联系我们。
''';

  // 用户协议内容
  static const String _termsOfServiceContent = '''
用户协议

1. 服务说明
Komorebi 提供本地笔记记录和云端同步服务。使用本应用即表示您同意本协议条款。

2. 账户注册
• 您需要提供有效的邮箱地址进行注册
• 您有责任维护账户安全
• 禁止分享账户或进行未经授权的访问

3. 使用规范
您同意不会：
• 使用本服务进行任何非法活动
• 上传恶意软件或病毒
• 干扰或破坏服务的正常运行
• 侵犯他人的知识产权

4. 服务变更
我们保留随时修改或终止服务的权利，会提前通知用户重大变更。

5. 免责声明
• 我们尽力确保服务稳定，但不保证无中断
• 用户需自行备份重要数据
• 因不可抗力导致的服务中断，我们不承担责任

6. 协议更新
我们可能会更新本协议，更新后会通过应用内通知您。

继续使用本应用即表示您接受更新后的协议。
''';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  /// 应用启动时自动检查更新（静默检查，不弹窗）
  Future<void> _autoCheckForUpdate() async {
    try {
      final updateInfo = await _feedbackService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        // 存储更新信息，等待用户进入设置页面时显示标记
        setState(() {
          _pendingUpdate = updateInfo;
        });
      }
    } catch (e) {
      // 静默失败，不影响用户体验
      if (kDebugMode) {
        print(' 自动检查更新失败: $e');
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // 🌟 显示反馈对话框
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const FeedbackDialog(),
    );
  }

  // 🌟 显示反馈历史
  void _showFeedbackHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const FeedbackHistoryPage()),
    );
  }

  // 🌟 检查更新交互
  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);

    // 如果有待显示的更新，直接显示对话框
    if (_pendingUpdate != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => UpdateDialog(updateInfo: _pendingUpdate!),
      );
      setState(() => _isCheckingUpdate = false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 20),
            const Text('正在检查新版本...', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );

    try {
      final updateInfo = await _feedbackService.checkForUpdate();
      
      if (!mounted) return;
      Navigator.pop(context); // 关闭 loading

      if (updateInfo != null) {
        // 有新版本
        setState(() => _pendingUpdate = updateInfo);
        showDialog(
          context: context,
          builder: (ctx) => UpdateDialog(updateInfo: updateInfo),
        );
      } else {
        // 已是最新
        final packageInfo = await PackageInfo.fromPlatform();
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => NoUpdateDialog(currentVersion: packageInfo.version),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭 loading
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('检查失败', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('无法连接到更新服务器，请检查网络后重试。'),
          actions: [
            FilledButton.tonal(onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  // 🌟 法律文档展示页面
  void _showLegalPage(String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          title == '隐私政策' ? Icons.verified_user_rounded : Icons.description_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 内容区域
                  _buildLegalContent(content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 解析并渲染法律文档内容
  Widget _buildLegalContent(String content) {
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 12));
      } else if (trimmed.startsWith('隐私政策') || trimmed.startsWith('用户协议')) {
        // 跳过主标题，已经在顶部显示
        continue;
      } else if (trimmed.startsWith('最后更新日期')) {
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 20));
      } else if (RegExp(r'^\d+\.').hasMatch(trimmed)) {
        // 章节标题
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('•')) {
        // 列表项
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trimmed.substring(1).trim(),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // 普通段落
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('关于与帮助', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 品牌区域
          Center(
            child: Column(
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 12))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/icons/komorebi_icon_source.png', width: 88, height: 88, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Komorebi', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                  child: Text(_version, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ==========================================
          // 模块 1：更新与支持
          // ==========================================
          _buildSectionHeader(theme, '更新与服务'),
          _buildGroupContainer(theme, [
            _buildMenuRow(
              theme, 
              icon: Icons.update_rounded, 
              title: '检查更新', 
              subtitle: _pendingUpdate != null ? '新版本: ${_pendingUpdate!.version}' : null,
              badge: _pendingUpdate != null,
              onTap: _checkForUpdates,
            ),
            _buildDivider(theme),
            _buildMenuRow(theme, icon: Icons.forum_outlined, title: '反馈与帮助', subtitle: '提交反馈或查看反馈历史', onTap: _showFeedbackHistory),
          ]),
          const SizedBox(height: 32),

          // ==========================================
          // 模块 2：关于与法律
          // ==========================================
          _buildSectionHeader(theme, '关于与法律'),
          _buildGroupContainer(theme, [
            _buildMenuRow(theme, icon: Icons.verified_user_outlined, title: '隐私政策', onTap: () => _showLegalPage('隐私政策', _privacyPolicyContent)),
            _buildDivider(theme),
            _buildMenuRow(theme, icon: Icons.description_outlined, title: '用户协议', onTap: () => _showLegalPage('用户协议', _termsOfServiceContent)),
          ]),
          const SizedBox(height: 32),

          // ==========================================
          // 模块 3：开源与社区
          // ==========================================
          _buildSectionHeader(theme, '开源与社区'),
          _buildGroupContainer(theme, [
            _buildMenuRow(theme, icon: Icons.language_rounded, title: '官方网站', isExternal: true, onTap: () => _launchUrl('https://komorebi.app')),
            _buildDivider(theme),
            _buildMenuRow(theme, icon: Icons.code_rounded, title: 'GitHub 开源仓库', isExternal: true, onTap: () => _launchUrl('https://github.com/Yuki-alice/komorebi')),
          ]),
          const SizedBox(height: 48),

          // 底部信息
          Center(
            child: Column(
              children: [
                Text('© 2026 Komorebi Studio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.outlineVariant)),
                const SizedBox(height: 4),
                Text('Made with ❤️ & Flutter', style: TextStyle(fontSize: 11, color: theme.colorScheme.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 🌟 物理切圆角，完美解决水波纹溢出
  Widget _buildGroupContainer(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias, // 🔪 关键：裁切溢出的 Hover 效果
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Text(title, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 20),
      child: Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
    );
  }

  Widget _buildMenuRow(ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap, bool isExternal = false, String? subtitle, bool badge = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (badge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle, 
                      style: TextStyle(
                        fontSize: 12, 
                        color: badge ? Colors.orange.shade600 : theme.colorScheme.onSurfaceVariant,
                        fontWeight: badge ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(isExternal ? Icons.open_in_new_rounded : Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}