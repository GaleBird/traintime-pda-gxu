// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:watermeter/repository/logger.dart';

typedef RecoverableCacheReader = String? Function();
typedef RecoverableCacheDecoder<T> = T Function(String rawText);

T? loadRecoverableCache<T>({
  required String label,
  required File file,
  required RecoverableCacheReader readRawText,
  required RecoverableCacheDecoder<T> decode,
}) {
  try {
    final rawText = readRawText();
    if (rawText == null) {
      return null;
    }
    return decode(rawText);
  } catch (error, stackTrace) {
    log.warning(
      '[cacheRecovery][$label] Corrupted cache detected, deleting file.',
      error,
      stackTrace,
    );
    _deleteCorruptedCacheFile(label: label, file: file);
    return null;
  }
}

void _deleteCorruptedCacheFile({required String label, required File file}) {
  if (!file.existsSync()) {
    return;
  }
  try {
    file.deleteSync();
  } catch (error, stackTrace) {
    log.warning(
      '[cacheRecovery][$label] Failed to delete corrupted cache file.',
      error,
      stackTrace,
    );
  }
}
