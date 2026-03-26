// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:watermeter/repository/classtable_storage.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_selection_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_session.dart';
import 'package:watermeter/repository/network_session.dart';

const String gxuNetworkCacheName = 'GxuNetworkUsage.json';

void removeCacheFiles() {
  _removeFiles([
    ClasstableStorage.schoolClassName,
    GxuScoreSession.scoreListCacheName,
    GxuCourseSelectionSession.courseSelectionCacheName,
    gxuNetworkCacheName,
  ]);
  resetGxuNetworkRuntimeState();
}

void removeAllFiles() {
  _removeFiles([
    ClasstableStorage.schoolClassName,
    ClasstableStorage.userDefinedClassName,
    ClasstableStorage.decorationName,
    GxuScoreSession.scoreListCacheName,
    GxuCourseSelectionSession.courseSelectionCacheName,
    gxuNetworkCacheName,
  ]);
  resetGxuNetworkRuntimeState();
}

void _removeFiles(List<String> names) {
  for (final name in names) {
    final file = File('${supportPath.path}/$name');
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
