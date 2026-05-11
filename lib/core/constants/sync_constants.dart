/// 同步相关常量
///
/// 集中管理 Supabase / WebDAV / LAN 同步流程中使用的重试、超时、批次等参数。
class SyncConstants {
  SyncConstants._();

  // ---- 重试策略 ----
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration networkTimeout = Duration(seconds: 15);
  static const double backoffMultiplier = 1.5;

  // ---- Supabase 批量查询 ----
  static const int supabaseBatchSize = 50;

  // ---- 笔记大小估算 ----
  static const int utf16BytesPerChar = 2;
  static const int noteMetadataOverheadBytes = 2048;

  // ---- 图片并发下载 ----
  static const int imageDownloadConcurrencyNormal = 5;
  static const int imageDownloadConcurrencyPrivate = 2;

  // ---- 云端文件列表查询上限 ----
  static const int cloudFileListLimit = 5000;

  // ---- LAN 同步 ----
  static const Duration lanRadarRestartDelay = Duration(milliseconds: 500);
  static const Duration lanConnectionTimeout = Duration(seconds: 10);

  // ---- 数据格式版本 ----
  static const int dataFormatVersion = 2;

  // ---- 默认值 ----
  static const int defaultVersion = 1;
  static const double defaultSortOrder = 0.0;
}
