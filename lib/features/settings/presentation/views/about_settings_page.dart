import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/support/feedback_service.dart';
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

  static const String _privacyPolicy = '''
## 隐私政策

*生效日期：2026 年 5 月 18 日*

感谢您使用 Komorebi（光隙笔记）。我们深知隐私的重要性，本政策旨在清晰透明地说明我们如何收集、使用和保护您的信息。

---

### 1. 信息收集

为提供核心服务，我们可能收集以下信息：

- **账户信息**：注册时需提供电子邮箱地址，用于账户创建、身份验证及密码找回。
- **设备信息**：操作系统版本、应用版本号，仅用于兼容性优化和问题诊断。
- **崩溃与性能数据**：应用崩溃日志和匿名性能指标，帮助我们持续改进产品稳定性。
- **同步数据**：您主动启用的云端同步功能所涉及的笔记内容和待办事项。

**我们不会收集**：您的通讯录、位置信息、浏览历史或任何超出上述范围的数据。

---

### 2. 数据存储与控制

- **本地存储**：您的笔记和待办数据优先存储在设备本地，您拥有完全的控制权，可随时导出或删除。
- **云端同步**：当您启用云端同步时，数据通过加密传输至 Supabase 云端服务，静态数据同样经过加密存储。
- 我们不会以任何形式出售、出租您的数据，也不会将笔记内容用于广告投放或商业分析。

---

### 3. 数据安全

我们采取行业标准的安全措施保护您的数据：

- 所有云端通信使用 TLS 加密传输。
- 数据库层面采用字段级加密，关键操作需身份令牌验证。
- 提供隐私空间功能，敏感笔记可独立加密存储。

尽管我们竭尽全力，没有任何在线服务能做到 100% 安全。我们建议您使用强密码并妥善保管账户凭证。

---

### 4. 第三方服务

本应用依赖以下第三方服务：

| 服务 | 用途 |
|------|------|
| Supabase | 账户认证、云端数据存储与同步 |

上述服务仅用于实现本应用的核心功能，其数据处理遵循各自的服务协议与隐私政策。

---

### 5. 您的权利

根据适用的数据保护法律，您享有以下权利：

- **访问权**：查看我们持有的与您相关的个人信息。
- **更正权**：更正不准确或不完整的信息。
- **删除权**：删除您的账户及关联的所有数据。
- **数据可携带权**：以 ZIP 格式导出您的全部数据（含笔记、图片和待办事项）。

您可以在应用「设置」中随时注销账户或导出数据。注销后，所有云端数据将被永久删除且不可恢复。

---

### 6. 儿童隐私

本服务不面向 13 周岁以下的儿童。我们不会在知情的情况下收集儿童的个人信息。如发现此类情况，我们将立即删除相关数据。

---

### 7. 政策更新

我们可能会不时更新本隐私政策。重大变更将通过应用内通知方式告知您。继续使用本应用即表示您同意更新后的政策。

---

### 8. 联系我们

如对本隐私政策有任何疑问或关切，请通过应用内「反馈与帮助」功能联系我们，我们将尽快回复。
''';

  static const String _termsOfService = '''
## 服务条款

*生效日期：2026 年 5 月 18 日*

欢迎使用 Komorebi（光隙笔记）。使用本应用及相关服务即表示您同意遵守本服务条款。如不同意，请停止使用本服务。

---

### 1. 服务说明

Komorebi 是一款笔记与任务管理应用，提供以下服务：

- 本地笔记与待办事项的创建、编辑与组织。
- 可选的云端同步服务，实现多设备间的数据互通。
- 数据备份与导出功能。

部分功能（如云端同步）需要注册账户并保持网络连接。

---

### 2. 账户注册与安全

- 您需提供真实、有效的电子邮箱地址完成注册。
- 您对账户下的所有活动负责，请妥善保管登录凭证。
- 如发现账户未经授权使用，请立即联系我们的支持团队。
- 禁止转让、出售或与他人共享账户。

---

### 3. 用户行为规范

使用本服务时，您同意不会从事以下行为：

- 违反任何适用的法律法规；
- 上传、传播恶意软件、病毒或任何破坏性代码；
- 干扰、破坏或对服务施加不合理负载；
- 侵犯他人知识产权、隐私权或其他合法权益；
- 利用服务进行垃圾信息分发、网络钓鱼或任何欺诈活动；
- 未经授权访问、探测或测试系统漏洞。

我们保留对违反上述规范的行为采取暂停或终止服务的权利。

---

### 4. 知识产权

- 您在应用中创建的内容归您所有，我们不主张任何所有权。
- 应用的代码、设计、品牌标识及名称「Komorebi / 光隙笔记」的版权及其他知识产权归属开发团队所有。
- 本应用基于开放源代码许可发布，具体条款见 GitHub 仓库中的 LICENSE 文件。

---

### 5. 服务可用性与变更

- 我们努力维持服务的稳定运行，但不对服务的持续无中断做出保证。
- 我们可能因维护、安全事件或不可控因素暂停或调整服务，重大变更将提前通过应用内通知告知。
- 我们保留随时修改、新增或终止部分功能的权利。

---

### 6. 免责声明

在适用法律允许的最大范围内：

- 本服务以「现状」提供，不附带任何形式的明示或默示担保。
- 我们不对因使用本服务造成的任何间接、附带或结果性损失承担责任。
- 数据安全是用户与我们的共同责任，建议您定期备份重要数据。
- 因自然灾害、战争、网络攻击等不可抗力事件导致的服务中断，我们免于承担相关责任。

---

### 7. 账户注销与终止

- 您可以在「设置」中随时注销账户，注销后所有云端数据将被永久删除。
- 若您违反本协议，我们有权暂停或终止您的账户访问权限。
- 协议终止后，第 3、4、6 条规定的义务将继续有效。

---

### 8. 适用法律

本协议的订立、执行与解释适用中华人民共和国法律。如产生争议，双方应首先友好协商；协商不成的，提交有管辖权的法院裁决。

---

### 9. 协议更新

我们可能会不时更新本服务条款。重大变更将通过应用内通知及/或电子邮件告知您。变更生效后继续使用本服务即视为接受更新的条款。

---

如对本协议有任何疑问，请通过应用内「反馈与帮助」功能联系我们。
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
            child: Markdown(
              data: content,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              physics: const BouncingScrollPhysics(),
              styleSheet: MarkdownStyleSheet(
                h2: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                h3: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                p: TextStyle(fontSize: 14, height: 1.7, color: Theme.of(context).colorScheme.onSurfaceVariant),
                listBullet: TextStyle(fontSize: 14, height: 1.6, color: Theme.of(context).colorScheme.onSurfaceVariant),
                em: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                strong: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2))),
                ),
                tableBorder: TableBorder.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                tableHead: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                tableBody: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
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
            _buildMenuRow(theme, icon: Icons.verified_user_outlined, title: '隐私政策', onTap: () => _showLegalPage('隐私政策', _privacyPolicy)),
            _buildDivider(theme),
            _buildMenuRow(theme, icon: Icons.description_outlined, title: '用户协议', onTap: () => _showLegalPage('用户协议', _termsOfService)),
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