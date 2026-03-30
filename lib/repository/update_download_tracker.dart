import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:watermeter/model/pda_service/message.dart';
import 'package:watermeter/repository/fork_info.dart';
import 'package:watermeter/repository/logger.dart';

const Duration _downloadCountTimeout = Duration(seconds: 2);
const List<String> _supportedAndroidDownloadRoutes = <String>[
  'arm64-v8a',
  'armeabi-v7a',
  'x86_64',
  'x86',
];

class AndroidUpdateDownloadTarget {
  const AndroidUpdateDownloadTarget({required this.downloadUrl, this.routeId});

  final String downloadUrl;
  final String? routeId;
}

String? resolveAndroidDownloadRouteId(String assetName) {
  final normalized = assetName.trim().toLowerCase();
  for (final routeId in _supportedAndroidDownloadRoutes) {
    if (_matchesDownloadRoute(normalized, routeId)) {
      return routeId;
    }
  }
  return null;
}

bool _matchesDownloadRoute(String assetName, String routeId) {
  final pattern = RegExp(
    '(^|[^a-z0-9_])${RegExp.escape(routeId)}([^a-z0-9_]|\$)',
  );
  return pattern.hasMatch(assetName);
}

Uri buildAndroidDownloadCountUri(String routeId) {
  if (!_supportedAndroidDownloadRoutes.contains(routeId)) {
    throw ArgumentError.value(
      routeId,
      'routeId',
      'Unsupported Android download route.',
    );
  }
  final websiteUri = Uri.parse(ForkInfo.officialWebsiteUrl);
  return websiteUri.replace(path: '/api/downloads/$routeId/count');
}

Future<void> openAndroidUpdateDownload(UpdateMessage updateMessage) async {
  final routeId = updateMessage.androidDownloadRouteId;
  if (routeId != null) {
    await _recordAndroidDownloadCount(routeId);
  }
  await launchUrlString(updateMessage.fdroid);
}

Future<void> _recordAndroidDownloadCount(String routeId) async {
  try {
    await _createDownloadCountDio().postUri(
      buildAndroidDownloadCountUri(routeId),
    );
  } catch (e, s) {
    log.warning('[update][downloadCount] failed', e, s);
  }
}

Dio _createDownloadCountDio() {
  return Dio(
    BaseOptions(
      connectTimeout: _downloadCountTimeout,
      receiveTimeout: _downloadCountTimeout,
      sendTimeout: _downloadCountTimeout,
    ),
  )..interceptors.add(logDioAdapter);
}
