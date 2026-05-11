// 本地删除记录与废纸篓处理
// 负责将本地删除操作记录到 SharedPreferences，并在同步时批量清理云端对应记录。
// 支持 Todo、Note、Category、Tag 四种实体的删除黑名单机制。

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_models.dart';
import 'supabase_retry_wrapper.dart';

class SupabaseDeletionSync {
  final SupabaseClient _supabase;
  final SupabaseRetryWrapper _retry;

  SupabaseDeletionSync(this._supabase, this._retry);

  Future<void> recordDeletedTodoId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(deletedTodosKey) ?? [];
    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList(deletedTodosKey, deletedIds);
      SyncLogger.info('TODO', '记录本地待删除 Todo ID: $id');
    }
  }

  Future<void> recordDeletedNoteId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(deletedNotesKey) ?? [];
    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList(deletedNotesKey, deletedIds);
      SyncLogger.info('NOTE', '记录本地待删除 Note ID: $id');
    }
  }

  Future<void> recordDeletedCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedCats = prefs.getStringList(deletedCategoriesKey) ?? [];
    if (!deletedCats.contains(categoryId)) {
      deletedCats.add(categoryId);
      await prefs.setStringList(deletedCategoriesKey, deletedCats);
      SyncLogger.info('CATE', '记录本地待删除分类: $categoryId');
    }
  }

  Future<void> recordDeletedTag(String tagId) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedTags = prefs.getStringList(deletedTagsKey) ?? [];
    if (!deletedTags.contains(tagId)) {
      deletedTags.add(tagId);
      await prefs.setStringList(deletedTagsKey, deletedTags);
      SyncLogger.info('TAG', '记录本地待删除标签: $tagId');
    }
  }

  /// 处理本地删除记录：批量清理云端废纸篓
  Future<void> processLocalDeletions(SharedPreferences prefs, String table, String key) async {
    final deletedIds = prefs.getStringList(key) ?? [];
    if (deletedIds.isEmpty) return;
    try {
      await _retry.withRetry(
        operation: () => _supabase.from(table).delete().inFilter('id', deletedIds),
        operationName: '清理云端废纸篓',
      );
      await prefs.setStringList(key, []);
      SyncLogger.info('TRASH', '成功清空 [$table] 云端废纸篓: ${deletedIds.length} 条');
    } catch (e) {
      SyncLogger.error('TRASH', '清理 [$table] 废纸篓失败', e);
    }
  }
}
