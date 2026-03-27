import 'dart:io';

import 'package:dio/dio.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_empty_classroom_parser.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class GxuEmptyClassroomSession {
  static const _pageItemId = "up_033_006_003";
  static const _pagePath =
      "/yjs/py/jsgl/cxkxjs/cxkxjsIndex/js?item_id=$_pageItemId";
  static const _findAllClassroomsPath = "/yjs/py/pkxxgl/findAllJsxx";
  static const _findOccupancyPath = "/yjs/py/pkxxgl/findJszyqk";
  static const _detailPath = "/yjs/py/pkxxgl/getJszyqkByJsxxid";
  static const _portalRefererPath = "/view?m=up";

  final GxuCASession caSession;
  final GxuEmptyClassroomParser parser;

  GxuEmptyClassroomSession({
    GxuCASession? caSession,
    GxuEmptyClassroomParser? parser,
  }) : caSession = caSession ?? GxuCASession(),
       parser = parser ?? GxuEmptyClassroomParser();

  Future<GxuEmptyClassroomQueryForm> loadQueryForm() async {
    await _ensureLoggedIn();
    final htmlResponse = await _request(
      () => caSession.dio.get(_pageUrl, options: _pageOptions()),
      scene: "空教室页面",
    );
    final html = _requireHtml(htmlResponse, scene: "空教室页面");
    final baseForm = parser.parseQueryPage(html);
    final catalogResponse = await _request(
      () => caSession.dio.post(
        "$_baseUrl$_findAllClassroomsPath",
        options: _ajaxOptions(),
      ),
      scene: "空教室教室目录",
    );
    final catalog = parser.parseClassroomCatalog(catalogResponse.data);
    return baseForm.withClassroomCatalog(catalog);
  }

  Future<GxuEmptyClassroomResult> search(
    GxuEmptyClassroomQueryForm form,
  ) async {
    await _ensureLoggedIn();
    final response = await _request(
      () => caSession.dio.post(
        "$_baseUrl$_findOccupancyPath",
        data: form.toPayload(),
        options: _ajaxOptions(),
      ),
      scene: "空教室查询结果",
    );
    final result = parser.parseResultPayload(response.data);
    _ensureResultViewTypeCompatible(result: result, viewType: form.viewType);
    return result;
  }

  Future<String> loadCellDetail({
    required GxuEmptyClassroomQueryForm form,
    required GxuEmptyClassroomCell cell,
  }) async {
    if (cell.localDetailMessage != null) {
      return cell.localDetailMessage!;
    }
    final response = await _request(
      () => caSession.dio.post(
        "$_baseUrl$_detailPath",
        data: {
          "type": cell.viewType.remoteType.toString(),
          "jsxxid": cell.roomId,
          "num": cell.slotNumber.toString(),
          "kszc": form.selectField("kszc")?.selectedValue ?? "",
          "jszc": form.selectField("jszc")?.selectedValue ?? "",
          "ksxq": form.selectField("ksxq")?.selectedValue ?? "",
          "jsxq": form.selectField("jsxq")?.selectedValue ?? "",
          "ksjc": form.selectField("ksjc")?.selectedValue ?? "",
          "jsjc": form.selectField("jsjc")?.selectedValue ?? "",
          "zyqk": form.selectField("zyqk")?.selectedValues.join(",") ?? "",
          "xqdm": form.selectField("xqdm")?.selectedValue ?? "",
          "zylx": form.selectField("zylx")?.selectedValue ?? "",
        },
        options: _ajaxOptions(),
      ),
      scene: "空教室占用详情",
    );
    return parser.parseDetailPayload(response.data);
  }

  Future<void> _ensureLoggedIn() {
    return caSession.ensureYjsxtLoggedIn(
      username: preference.getString(preference.Preference.idsAccount),
      password: preference.getString(preference.Preference.idsPassword),
    );
  }

  void _ensureResultViewTypeCompatible({
    required GxuEmptyClassroomResult result,
    required GxuEmptyClassroomViewType viewType,
  }) {
    final rooms = result.rooms;
    var hasAnyKey = false;
    var hasWeekKey = false;
    var hasWeekdayKey = false;
    var hasPeriodKey = false;

    for (final room in rooms) {
      if (!hasAnyKey &&
          (room.schedule.isNotEmpty ||
              room.exam.isNotEmpty ||
              room.borrow.isNotEmpty ||
              room.adjust.isNotEmpty ||
              room.other.isNotEmpty)) {
        hasAnyKey = true;
      }
      if (hasWeekKey && hasWeekdayKey && hasPeriodKey) {
        break;
      }
      void scanKeys(Iterable<String> keys) {
        for (final key in keys) {
          if (!hasWeekKey && key.startsWith("zc")) {
            hasWeekKey = true;
          } else if (!hasWeekdayKey && key.startsWith("xq")) {
            hasWeekdayKey = true;
          } else if (!hasPeriodKey && key.startsWith("jc")) {
            hasPeriodKey = true;
          }
          if (hasWeekKey && hasWeekdayKey && hasPeriodKey) {
            return;
          }
        }
      }

      scanKeys(room.schedule.keys);
      scanKeys(room.exam.keys);
      scanKeys(room.borrow.keys);
      scanKeys(room.adjust.keys);
      scanKeys(room.other.keys);
    }

    if (!hasAnyKey) {
      return;
    }

    final supportsSelected = switch (viewType) {
      GxuEmptyClassroomViewType.week => hasWeekKey,
      GxuEmptyClassroomViewType.weekday => hasWeekdayKey,
      GxuEmptyClassroomViewType.period => hasPeriodKey,
    };
    if (supportsSelected) {
      return;
    }

    final supported = <String>[
      if (hasWeekKey) "按周次",
      if (hasWeekdayKey) "按星期",
      if (hasPeriodKey) "按节次",
    ];
    final selectedLabel = switch (viewType) {
      GxuEmptyClassroomViewType.week => "按周次",
      GxuEmptyClassroomViewType.weekday => "按星期",
      GxuEmptyClassroomViewType.period => "按节次",
    };
    final suggestion = supported.isEmpty ? "按节次" : supported.join(" / ");
    final sampleKeys = _sampleResultKeys(rooms);
    final hint = sampleKeys.isEmpty ? "" : "（接口键示例：$sampleKeys）";
    throw LoginFailedException(
      msg:
          "空教室查询结果缺少「$selectedLabel」所需数据，无法保证准确性；请切换查看方式为：$suggestion 后重新查询。$hint",
    );
  }

  String _sampleResultKeys(List<GxuEmptyClassroomRemoteRoom> rooms) {
    final keys = <String>[];
    void addKeys(Iterable<String> source) {
      for (final key in source) {
        if (keys.length >= 6) {
          return;
        }
        keys.add(key);
      }
    }

    for (final room in rooms) {
      addKeys(room.schedule.keys);
      addKeys(room.exam.keys);
      addKeys(room.borrow.keys);
      addKeys(room.adjust.keys);
      addKeys(room.other.keys);
      if (keys.length >= 6) {
        break;
      }
    }
    return keys.join(", ");
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() action, {
    required String scene,
  }) async {
    try {
      final response = await action();
      _ensureNotLoggedOut(response, scene: scene);
      return response;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw LoginFailedException(msg: "广西大学$scene地址已失效，当前模块路由可能已变更。");
      }
      rethrow;
    }
  }

  String _requireHtml(Response<dynamic> response, {required String scene}) {
    final html = response.data?.toString() ?? "";
    if (html.trim().isEmpty) {
      throw LoginFailedException(msg: "广西大学$scene返回为空。");
    }
    if (html.contains("统一身份认证") || html.contains("统一身份认证平台")) {
      throw LoginFailedException(msg: "广西大学$scene要求重新登录。");
    }
    return html;
  }

  void _ensureNotLoggedOut(
    Response<dynamic> response, {
    required String scene,
  }) {
    final redirectTarget = response.headers.value(HttpHeaders.locationHeader);
    if (redirectTarget != null && redirectTarget.isNotEmpty) {
      throw LoginFailedException(msg: "广西大学$scene要求重新登录。");
    }
    final body = response.data?.toString() ?? "";
    if (body.contains("统一身份认证") || body.contains("统一身份认证平台")) {
      throw LoginFailedException(msg: "广西大学$scene要求重新登录。");
    }
  }

  Options _pageOptions() {
    return Options(
      headers: {
        HttpHeaders.acceptHeader: "text/html, */*; q=0.01",
        HttpHeaders.refererHeader: "$_baseUrl$_portalRefererPath",
        "Origin": "https://yjsxt.gxu.edu.cn",
        "X-Requested-With": "XMLHttpRequest",
      },
    );
  }

  Options _ajaxOptions() {
    return Options(
      headers: {
        HttpHeaders.acceptHeader:
            "application/json, text/javascript, */*; q=0.01",
        HttpHeaders.refererHeader: "$_baseUrl$_portalRefererPath",
        "Origin": "https://yjsxt.gxu.edu.cn",
        "X-Requested-With": "XMLHttpRequest",
      },
    );
  }

  String get _baseUrl => GxuCASession.yjsxtBase;

  String get _pageUrl => "$_baseUrl$_pagePath";
}
