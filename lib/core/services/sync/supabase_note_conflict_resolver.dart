// 笔记冲突解决
// 负责检测和处理笔记同步冲突，包括：
// - 基于版本号 + lastSyncedVersion 的冲突检测
// - 冲突对话框交互
// - 返回用户选择结果供调用方处理

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/note_repository.dart';
import '../../../widgets/common/dialogs/sync_conflict_dialog.dart';
import '../../../models/note.dart';

import 'sync_models.dart';

class SupabaseNoteConflictResolver {
  final SupabaseClient _supabase;
  final NoteRepository? _noteRepo;

  SupabaseNoteConflictResolver(
    this._supabase,
    this._noteRepo,
  );

  // =========================================================================
  // 冲突解决处理
  // =========================================================================

  /// 显示冲突对话框并返回用户选择
  /// 返回值: Map<noteId, choice> where choice is 'local', 'cloud', or 'skip'
  Future<Map<String, String>> resolveConflicts({
    required BuildContext context,
    required List<SyncConflict> conflicts,
  }) async {
    final results = <String, String>{};

    for (var conflict in conflicts) {
      if (!context.mounted) {
        SyncLogger.warn('CONFLICT', '上下文已销毁，中断冲突处理');
        break;
      }

      final note = _noteRepo?.getNoteById(conflict.noteId);
      final noteTitle = note?.title ?? '未命名笔记';

      SyncLogger.info('CONFLICT', '显示冲突对话框: $noteTitle');

      final result = await showSyncConflictDialog(
        context: context,
        noteTitle: noteTitle,
        localVersion: conflict.localVersion,
        cloudVersion: conflict.cloudVersion,
        localUpdatedAt: conflict.localUpdatedAt,
        cloudUpdatedAt: conflict.cloudUpdatedAt,
      );

      if (result == null) {
        SyncLogger.info('CONFLICT', '用户取消解决冲突: $noteTitle');
        results[conflict.noteId] = 'skip';
      } else {
        SyncLogger.info('CONFLICT', '用户选择保留$result: $noteTitle');
        results[conflict.noteId] = result;
      }
    }

    return results;
  }

  // =========================================================================
  // 核心对比算法（基于版本号）
  // =========================================================================

  /// 基于版本号 + lastSyncedVersion 的冲突检测
  ///
  /// 冲突判定：本地版本 > lastSyncedVersion 且 云端版本 > lastSyncedVersion
  /// 这意味着两端在最后一次同步后都有更新
  SyncPlan reconcileDataWithVersion({
    required Map<String, NoteSyncMeta> localMetaMap,
    required Map<String, CloudNoteMeta> cloudMetadata,
    required DateTime? lastSyncTime,
    required Map<String, int> lastSyncedVersions,
  }) {
    final toPull = <String>[];
    final toPush = <String>[];
    final toDeleteLocally = <String>[];
    final conflicts = <SyncConflict>[];

    for (var cloudMeta in cloudMetadata.entries) {
      final cloudId = cloudMeta.key;
      final cloudData = cloudMeta.value;
      final localData = localMetaMap[cloudId];
      final lastSyncedVersion = lastSyncedVersions[cloudId] ?? 1;

      if (localData == null) {
        toPull.add(cloudId);
      } else {
        final localUpdated = localData.version > lastSyncedVersion;
        final cloudUpdated = cloudData.version > lastSyncedVersion;

        if (localUpdated && cloudUpdated) {
          conflicts.add(SyncConflict(
            noteId: cloudId,
            localVersion: localData.version,
            cloudVersion: cloudData.version,
            localUpdatedAt: localData.updatedAt,
            cloudUpdatedAt: cloudData.updatedAt,
          ));
          SyncLogger.info(
            'CONFLICT',
            '检测到冲突: $cloudId (本地v${localData.version} vs 云端v${cloudData.version}, 上次同步v$lastSyncedVersion)',
          );
        } else if (cloudData.version > localData.version) {
          toPull.add(cloudId);
        } else if (cloudData.version < localData.version) {
          toPush.add(cloudId);
        } else {
          if (cloudData.updatedAt.difference(localData.updatedAt).inSeconds.abs() <= timeBuffer.inSeconds) {
            continue;
          }
          if (cloudData.updatedAt.isAfter(localData.updatedAt)) {
            toPull.add(cloudId);
          } else {
            toPush.add(cloudId);
          }
        }
      }
    }

    for (var localMeta in localMetaMap.entries) {
      final localId = localMeta.key;
      final localData = localMeta.value;

      if (!cloudMetadata.containsKey(localId)) {
        if (lastSyncTime == null) {
          toPush.add(localId);
        } else {
          if (localData.updatedAt.isAfter(lastSyncTime.add(timeBuffer))) {
            toPush.add(localId);
          } else {
            toDeleteLocally.add(localId);
          }
        }
      }
    }

    return SyncPlan(
      toPull: toPull,
      toPush: toPush,
      toDeleteLocally: toDeleteLocally,
      conflicts: conflicts,
    );
  }
}
