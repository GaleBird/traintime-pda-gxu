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
    return parser.parseResultPayload(response.data);
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

  void _ensureNotLoggedOut(Response<dynamic> response, {required String scene}) {
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
        HttpHeaders.acceptHeader: "application/json, text/javascript, */*; q=0.01",
        HttpHeaders.refererHeader: "$_baseUrl$_portalRefererPath",
        "Origin": "https://yjsxt.gxu.edu.cn",
        "X-Requested-With": "XMLHttpRequest",
      },
    );
  }

  String get _baseUrl => GxuCASession.yjsxtBase;

  String get _pageUrl => "$_baseUrl$_pagePath";
}
