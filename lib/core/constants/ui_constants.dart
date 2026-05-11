/// UI 相关常量
///
/// 集中管理动画时长、防抖延迟、自动保存、列表分页等参数。
class UiConstants {
  UiConstants._();

  // ---- 动画时长 ----
  static const Duration animationVeryFast = Duration(milliseconds: 100);
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 200);
  static const Duration animationStandard = Duration(milliseconds: 300);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationPageTransition = Duration(milliseconds: 600);

  // ---- 防抖 / 延迟 ----
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration backgroundSyncDebounce = Duration(seconds: 5);
  static const Duration backgroundSyncDebounceTodos = Duration(seconds: 3);
  static const Duration autoSaveDebounce = Duration(seconds: 3);

  // ---- 同步状态自动恢复 ----
  static const Duration syncSuccessResetDelay = Duration(seconds: 3);
  static const Duration syncErrorResetDelay = Duration(seconds: 5);

  // ---- 数据维护 ----
  static const int trashAutoCleanupDays = 30;
  static const int orphanTagGCMinutes = 60;

  // ---- 分页 ----
  static const int defaultPageSize = 20;

  // ---- 排序 ----
  static const double todoSortOrderGap = 100.0;
  static const double todoSortOrderWeight = 1000.0;

  // ---- AI ----
  static const double aiTemperature = 0.7;
  static const Duration aiRequestTimeout = Duration(seconds: 15);

  // ---- 下载超时 ----
  static const Duration downloadConnectTimeout = Duration(seconds: 30);
  static const Duration downloadReceiveTimeout = Duration(seconds: 60);

  // ---- 更新检查 ----
  static const int updateCheckFrequencyHours = 24;

  // ---- 窗口尺寸 ----
  static const double desktopDefaultWidth = 1024;
  static const double desktopDefaultHeight = 768;
  static const double desktopMinWidth = 360;
  static const double desktopMinHeight = 600;

  // ---- 统计 ----
  static const int wanCountThreshold = 10000;
}
