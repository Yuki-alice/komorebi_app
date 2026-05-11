// 待办同步
// 负责待办（Todo）的增量双向同步，包括：
// - 待办拉取与推送
// - 基于时间戳的冲突检测
// - 本地删除记录处理

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/todo_repository.dart';
import '../../../models/todo.dart';

import 'sync_models.dart';
import 'supabase_retry_wrapper.dart';
import 'supabase_deletion_sync.dart';

class SupabaseTodoSync {
  final SupabaseClient _supabase;
  final TodoRepository? _todoRepo;
  final SupabaseRetryWrapper _retry;
  final SupabaseDeletionSync _deletionSync;

  SupabaseTodoSync(
    this._supabase,
    this._todoRepo,
    this._retry,
    this._deletionSync,
  );

  // =========================================================================
  // 待办同步主入口
  // =========================================================================

  Future<void> syncTodos({Function()? onSyncComplete}) async {
    if (_todoRepo == null || _supabase.auth.currentUser == null) return;

    SyncLogger.info('TODO', '====== 🚀 启动待办同步管线 ======');
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = _supabase.auth.currentUser!.id;

      await _deletionSync.processLocalDeletions(prefs, 'todos', deletedTodosKey);

      final lastSyncStr = prefs.getString(lastTodoSyncKey);
      final lastSyncTime = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

      final cloudMetadata = await _fetchCloudMetadata(currentUserId);
      final localMetaMap = await _todoRepo!.getAllTodosMetadata();

      final plan = _reconcileData(
        localMetaMap: localMetaMap,
        cloudMetadata: cloudMetadata,
        lastSyncTime: lastSyncTime,
      );

      if (plan.toPull.isNotEmpty) {
        SyncLogger.info('SYNC', '📥 计划拉取 ${plan.toPull.length} 条待办从云端');
        await _pullTodos(plan.toPull, currentUserId, localMetaMap.keys.toSet());
      } else {
        SyncLogger.info('SYNC', '📥 无需拉取待办（云端无更新）');
      }

      if (plan.toPush.isNotEmpty) {
        SyncLogger.info('SYNC', '📤 计划推送 ${plan.toPush.length} 条待办到云端');
        await _pushTodos(plan.toPush, currentUserId);
      } else {
        SyncLogger.info('SYNC', '📤 无需推送待办（本地无更新）');
      }

      for (var id in plan.toDeleteLocally) {
        await _todoRepo!.deleteTodo(id);
        SyncLogger.info('TODO', '👻 成功抹除本地幽灵待办: $id');
      }

      await prefs.setString(lastTodoSyncKey, DateTime.now().toUtc().toIso8601String());
      if (onSyncComplete != null) onSyncComplete();

      SyncLogger.info('TODO', '====== ✅ 待办同步管线完美收官 ======');
    } catch (e) {
      SyncLogger.error('TODO', '同步管线崩溃', e);
    }
  }

  // =========================================================================
  // 待办拉取
  // =========================================================================

  Future<void> _pullTodos(List<String> idsToFetch, String userId, Set<String> existingLocalIds) async {
    int pullCount = 0;
    for (var i = 0; i < idsToFetch.length; i += 50) {
      final chunk = idsToFetch.sublist(i, i + 50 > idsToFetch.length ? idsToFetch.length : i + 50);
      final List<dynamic> cloudUpdates = await _retry.withRetry(
        operation: () => _supabase.from('todos').select().inFilter('id', chunk).eq('user_id', userId),
        operationName: '拉取待办详情',
      );

      for (var data in cloudUpdates) {
        List<SubTask> parsedSubTasks = [];
        if (data['sub_tasks'] != null) {
          final List<dynamic> stList = data['sub_tasks'] as List<dynamic>;
          parsedSubTasks = stList.map((e) => SubTask.fromMap(e as Map<String, dynamic>)).toList();
        }

        final updatedTodo = Todo(
          id: data['id'],
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          createdAt: DateTime.parse(data['created_at']).toLocal(),
          updatedAt: DateTime.parse(data['updated_at']).toLocal(),
          dueDate: data['due_date'] != null ? DateTime.parse(data['due_date']).toLocal() : null,
          isCompleted: data['is_completed'] ?? false,
          isDeleted: data['is_deleted'] ?? false,
          sortOrder: (data['sort_order'] as num?)?.toDouble() ?? 0.0,
          subTasks: parsedSubTasks,
        );

        if (existingLocalIds.contains(updatedTodo.id)) {
          await _todoRepo!.updateTodo(updatedTodo);
        } else {
          await _todoRepo!.addTodo(updatedTodo);
        }
        pullCount++;
      }
    }
    if (pullCount > 0) {
      SyncLogger.info('PULL', '✅ 成功拉取 $pullCount 条待办到本地');
    }
  }

  // =========================================================================
  // 待办推送
  // =========================================================================

  Future<void> _pushTodos(List<String> idsToPush, String userId) async {
    List<Map<String, dynamic>> payloads = [];
    for (var id in idsToPush) {
      final fullTodo = await _todoRepo!.getTodoById(id);
      if (fullTodo != null) {
        payloads.add({
          'id': fullTodo.id,
          'title': fullTodo.title,
          'description': fullTodo.description,
          'created_at': fullTodo.createdAt.toUtc().toIso8601String(),
          'updated_at': fullTodo.updatedAt.toUtc().toIso8601String(),
          'due_date': fullTodo.dueDate?.toUtc().toIso8601String(),
          'is_completed': fullTodo.isCompleted,
          'is_deleted': fullTodo.isDeleted,
          'sort_order': fullTodo.sortOrder,
          'user_id': userId,
          'sub_tasks': fullTodo.subTasks.map((st) => st.toMap()).toList(),
        });
      }
    }
    if (payloads.isNotEmpty) {
      await _retry.withRetry(
        operation: () => _supabase.from('todos').upsert(payloads),
        operationName: '推送待办到云端',
      );
      SyncLogger.info('PUSH', '✅ 成功推送 ${payloads.length} 条待办到云端');
    } else {
      SyncLogger.info('PUSH', 'ℹ️ 无待办需要推送');
    }
  }

  // =========================================================================
  // 待办对比算法（基于时间戳）
  // =========================================================================

  SyncPlan _reconcileData({
    required Map<String, DateTime> localMetaMap,
    required Map<String, DateTime> cloudMetadata,
    required DateTime? lastSyncTime,
  }) {
    final toPull = <String>[];
    final toPush = <String>[];
    final toDeleteLocally = <String>[];

    for (var cloudMeta in cloudMetadata.entries) {
      final cloudId = cloudMeta.key;
      final cloudTime = cloudMeta.value;
      final localTime = localMetaMap[cloudId];

      if (localTime == null) {
        toPull.add(cloudId);
      } else {
        if (cloudTime.difference(localTime).inSeconds.abs() <= timeBuffer.inSeconds) continue;

        if (cloudTime.isAfter(localTime)) {
          toPull.add(cloudId);
        } else {
          toPush.add(cloudId);
        }
      }
    }

    for (var localMeta in localMetaMap.entries) {
      final localId = localMeta.key;
      final localTime = localMeta.value;

      if (!cloudMetadata.containsKey(localId)) {
        if (lastSyncTime == null) {
          toPush.add(localId);
        } else {
          if (localTime.isAfter(lastSyncTime.add(timeBuffer))) {
            toPush.add(localId);
          } else {
            toDeleteLocally.add(localId);
          }
        }
      }
    }

    return SyncPlan(toPull: toPull, toPush: toPush, toDeleteLocally: toDeleteLocally);
  }

  // =========================================================================
  // 云端元数据获取
  // =========================================================================

  Future<Map<String, DateTime>> _fetchCloudMetadata(String userId) async {
    try {
      final response = await _retry.withRetry(
        operation: () => _supabase.from('todos').select('id, updated_at').eq('user_id', userId),
        operationName: '拉取云端元数据',
      );
      final data = response as List<dynamic>;
      SyncLogger.info('META', '从云端 [todos] 发现 ${data.length} 条记录');
      return {for (var item in data) item['id'].toString(): DateTime.parse(item['updated_at'].toString()).toLocal()};
    } catch (e) {
      SyncLogger.error('META', '拉取 [todos] 元数据超时或失败', e);
      return {};
    }
  }
}
