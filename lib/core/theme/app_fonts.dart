import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Komorebi 商业级字体配置系统（性能优化版）
/// 
/// 设计原则：
/// 1. 中文优先：使用 Noto Sans/Serif SC 保证中文显示效果
/// 2. 西文搭配：使用 Inter 作为西文无衬线字体
/// 3. 代码专用：Fira Code 保持等宽特性
/// 4. 双端适配：桌面端更大字号，手机端紧凑排版
/// 5. 性能优化：预加载字体，避免运行时网络请求
class AppFonts {
  AppFonts._();

  // ============================================
  // 字体家族定义
  // ============================================
  
  /// 主字体：Noto Sans SC（思源黑体）- 适合正文和UI
  static String get primaryFont => 'Noto Sans SC';
  
  /// 阅读字体：Noto Serif SC（思源宋体）- 适合长文阅读
  static String get readingFont => 'Noto Serif SC';
  
  /// 西文字体：Inter - 现代、清晰
  static String get latinFont => 'Inter';
  
  /// 代码字体：Fira Code - 等宽、连字支持
  static String get codeFont => 'Fira Code';

  // ============================================
  // 字体加载器（单例，避免重复创建）
  // ============================================
  
  static TextStyle? _cachedNotoSansSc;
  static TextStyle? _cachedNotoSerifSc;
  static TextStyle? _cachedFiraCode;
  
  /// 获取 Noto Sans SC 基础样式（带缓存）
  static TextStyle _getNotoSansScBase() {
    _cachedNotoSansSc ??= GoogleFonts.notoSansSc();
    return _cachedNotoSansSc!;
  }
  
  /// 获取 Noto Serif SC 基础样式（带缓存）
  static TextStyle _getNotoSerifScBase() {
    _cachedNotoSerifSc ??= GoogleFonts.notoSerifSc();
    return _cachedNotoSerifSc!;
  }
  
  /// 获取 Fira Code 基础样式（带缓存）
  static TextStyle _getFiraCodeBase() {
    _cachedFiraCode ??= GoogleFonts.firaCode();
    return _cachedFiraCode!;
  }

  // ============================================
  // 预加载字体（在应用启动时调用）
  // ============================================
  
  static Future<void> preloadFonts() async {
    // 预加载所有常用字体，避免首次使用时的网络请求
    await GoogleFonts.pendingFonts([
      GoogleFonts.notoSansSc(),
      GoogleFonts.notoSerifSc(),
      GoogleFonts.firaCode(),
    ]);
  }

  // ============================================
  // 桌面端字体配置
  // ============================================
  
  /// 桌面端正文样式
  static TextStyle desktopBody(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 17,
      height: 1.8,
      letterSpacing: 0.3,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );
  }
  
  /// 桌面端标题样式
  static TextStyle desktopH1(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: 0.5,
      color: theme.colorScheme.onSurface,
    );
  }
  
  static TextStyle desktopH2(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: 0.3,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
    );
  }
  
  static TextStyle desktopH3(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );
  }
  
  /// 桌面端引用样式
  static TextStyle desktopQuote(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSerifScBase().copyWith(
      fontSize: 16,
      height: 1.7,
      letterSpacing: 0.2,
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
  
  /// 桌面端代码样式
  static TextStyle desktopCode(BuildContext context) {
    final theme = Theme.of(context);
    return _getFiraCodeBase().copyWith(
      fontSize: 15,
      height: 1.6,
      letterSpacing: 0,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
  
  /// 桌面端列表样式
  static TextStyle desktopList(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 17,
      height: 1.6,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );
  }

  // ============================================
  // 手机端字体配置（更紧凑）
  // ============================================
  
  /// 手机端正文样式
  static TextStyle mobileBody(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 16,
      height: 1.75,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );
  }
  
  /// 手机端标题样式
  static TextStyle mobileH1(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: 0.3,
      color: theme.colorScheme.onSurface,
    );
  }
  
  static TextStyle mobileH2(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 23,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
    );
  }
  
  static TextStyle mobileH3(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.1,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );
  }
  
  /// 手机端引用样式
  static TextStyle mobileQuote(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSerifScBase().copyWith(
      fontSize: 15,
      height: 1.65,
      letterSpacing: 0.1,
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
  
  /// 手机端代码样式
  static TextStyle mobileCode(BuildContext context) {
    final theme = Theme.of(context);
    return _getFiraCodeBase().copyWith(
      fontSize: 14,
      height: 1.55,
      letterSpacing: 0,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
  
  /// 手机端列表样式
  static TextStyle mobileList(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 16,
      height: 1.55,
      letterSpacing: 0.1,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );
  }

  // ============================================
  // 编辑器标题专用样式
  // ============================================
  
  /// 桌面端编辑器标题
  static TextStyle desktopEditorTitle(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 38,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: 0.5,
      color: theme.colorScheme.onSurface,
    );
  }
  
  /// 手机端编辑器标题
  static TextStyle mobileEditorTitle(BuildContext context) {
    final theme = Theme.of(context);
    return _getNotoSansScBase().copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: 0.3,
      color: theme.colorScheme.onSurface,
    );
  }

  // ============================================
  // 辅助方法
  // ============================================
  
  /// 根据平台获取合适的正文样式
  static TextStyle body(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopBody(context) : mobileBody(context);
  }
  
  /// 根据平台获取合适的标题样式
  static TextStyle h1(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopH1(context) : mobileH1(context);
  }
  
  static TextStyle h2(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopH2(context) : mobileH2(context);
  }
  
  static TextStyle h3(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopH3(context) : mobileH3(context);
  }
  
  /// 根据平台获取合适的引用样式
  static TextStyle quote(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopQuote(context) : mobileQuote(context);
  }
  
  /// 根据平台获取合适的代码样式
  static TextStyle code(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopCode(context) : mobileCode(context);
  }
  
  /// 根据平台获取合适的列表样式
  static TextStyle list(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopList(context) : mobileList(context);
  }
  
  /// 编辑器标题样式
  static TextStyle editorTitle(BuildContext context, {bool isDesktop = false}) {
    return isDesktop ? desktopEditorTitle(context) : mobileEditorTitle(context);
  }
}
