import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';

enum ResourceSyncState {
  none(Icons.block),
  waiting(Icons.cloud_queue),
  error(Icons.sync_problem),
  syncing(Icons.sync);

  const ResourceSyncState(this.icon);

  final IconData icon;

  factory ResourceSyncState.fromStatus(ActionStatus status) {
    if (status is ActionStatusReady || status is ActionStatusWaiting) {
      return ResourceSyncState.waiting;
    }
    if (status is ActionStatusUploading) {
      return ResourceSyncState.syncing;
    }
    if (status is ActionStatusError) {
      return ResourceSyncState.error;
    }
    return ResourceSyncState.none;
  }
}
