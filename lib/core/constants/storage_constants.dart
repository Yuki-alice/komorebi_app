/// 存储 / 配额相关常量
///
/// 集中管理存储配额、图片压缩、字节换算等参数。
class StorageConstants {
  StorageConstants._();

  // ---- 字节换算 ----
  static const int bytesPerKB = 1024;
  static const int bytesPerMB = 1024 * 1024;
  static const int bytesPerGB = 1024 * 1024 * 1024;
  static const int mbPerGB = 1024;

  // ---- 配额默认值 (Free Plan) ----
  static const int freeStorageLimitMB = 100;
  static const int freeNoteCountLimit = 100;
  static const int freeImageCountLimit = 500;
  static const int freeTodoCountLimit = 50;

  // ---- 配额阈值 ----
  static const int quotaWarningPercent = 80;
  static const int quotaCriticalPercent = 90;
  static const int quotaExceededPercent = 100;

  // ---- 配额缓存 ----
  static const Duration quotaCacheDuration = Duration(minutes: 5);
  static const Duration quotaRefreshInterval = Duration(minutes: 5);

  // ---- 图片压缩 ----
  static const int jpegCompressionQuality = 80;
  static const int pngCompressionLevel = 6;
  static const int maxImageDimension = 1920;
  static const int maxImageDimensionHeight = 1080;

  // ---- 反馈截图压缩 ----
  static const int feedbackImageQuality = 80;
  static const int feedbackMaxTextLength = 500;

  // ---- 存储历史查询 ----
  static const int storageHistoryDefaultDays = 30;
  static const int recentLogsLimit = 50;

  // ---- PBKDF2 / 加密 ----
  static const int pbkdf2Iterations = 10000;
  static const int aesKeyLength = 32;
  static const int sha256HashLength = 32;
  static const int saltLength = 16;
  static const int aesGcmIvLength = 12;

  // ---- 自动锁定 ----
  static const Duration privacyAutoLockTimeout = Duration(minutes: 5);
}
