import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

/// 渐变背景容器 - 根据主题 vibe 自动切换 solid/gradient
class GradientBackground extends StatelessWidget {
  final Widget child;
  final ThemeVibe vibe;
  final Color seedColor;
  final bool isDark;

  const GradientBackground({
    super.key,
    required this.child,
    required this.vibe,
    required this.seedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 根据 vibe 决定背景类型
    if (vibe == ThemeVibe.gradient) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: child,
      );
    }

    // Solid 风格使用纯色背景
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      color: isDark ? const Color(0xFF1A1C1E) : const Color(0xFFFDFDFD),
      child: child,
    );
  }

  List<Color> _getGradientColors() {
    // 获取 RGB 值 (0-255)
    final r = seedColor.r.toInt();
    final g = seedColor.g.toInt();
    final b = seedColor.b.toInt();

    if (isDark) {
      // 深色模式渐变 - 更柔和的暗色调
      return [
        Color.fromRGBO(
          (r * 0.15).toInt(),
          (g * 0.15).toInt(),
          (b * 0.15).toInt(),
          1.0,
        ),
        const Color(0xFF1A1C1E),
      ];
    }

    // 浅色模式渐变 - 从极淡的品牌色到纯白
    return [
      Color.fromRGBO(
        (r * 0.08 + 245).toInt(),
        (g * 0.08 + 250).toInt(),
        (b * 0.08 + 249).toInt(),
        1.0,
      ),
      const Color(0xFFFDFDFD),
    ];
  }
}

/// 页面渐变背景包装器
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final ThemeVibe vibe;
  final Color seedColor;
  final bool isDark;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    required this.vibe,
    required this.seedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: GradientBackground(
        vibe: vibe,
        seedColor: seedColor,
        isDark: isDark,
        child: body,
      ),
    );
  }
}
