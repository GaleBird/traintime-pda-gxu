import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_page.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';
import 'package:watermeter/repository/gxu_ids/gxu_empty_classroom_session.dart';
import 'package:watermeter/repository/network_session.dart' as network_session;
import 'package:watermeter/repository/preference.dart' as preference;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempSupportDir;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    preference.prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    tempSupportDir = await Directory.systemTemp.createTemp(
      'gxu_empty_classroom_page_test',
    );
    network_session.supportPath = tempSupportDir;
  });

  tearDown(() async {
    if (tempSupportDir.existsSync()) {
      await tempSupportDir.delete(recursive: true);
    }
  });

  testWidgets('expanding advanced filters does not throw', (tester) async {
    final state = GxuEmptyClassroomState(
      session: _FakeEmptyClassroomSession(form: _buildForm()),
    );
    await tester.binding.setSurfaceSize(const Size(418, 429));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: [
            FlutterI18nDelegate(translationLoader: _TestTranslationLoader()),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('zh', 'TW'),
            Locale('en', 'US'),
          ],
          home: const Scaffold(body: GxuEmptyClassroomPage()),
        ),
      ),
    );

    await state.initialize();
    await tester.pumpAndSettle();

    final toggle = find.byKey(
      const Key('gxu_empty_classroom_advanced_filters_toggle'),
    );
    final trigger = tester.widget<InkWell>(toggle);
    trigger.onTap?.call();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _FakeEmptyClassroomSession extends GxuEmptyClassroomSession {
  final GxuEmptyClassroomQueryForm form;

  _FakeEmptyClassroomSession({required this.form});

  @override
  Future<GxuEmptyClassroomQueryForm> loadQueryForm() async => form;

  @override
  Future<GxuEmptyClassroomResult> search(GxuEmptyClassroomQueryForm form) {
    throw UnimplementedError();
  }
}

class _TestTranslationLoader extends TranslationLoader {
  @override
  Future<Map> load() async {
    return <String, dynamic>{
      'confirm': '确认',
      'click_to_refresh': '点击重试',
      'query_failed': '查询失败',
      'empty_classroom': <String, dynamic>{
        'filters': '筛选条件',
        'query_hint': '请选择条件后再查询',
        'semester_hint': '学期选择',
        'building_hint': '教学楼选择',
        'classroom_hint': '教室选择',
        'range_title': '时间范围',
        'range_hint': '选择起止周次、星期和节次',
        'range_week': '周次',
        'range_weekday': '星期',
        'range_period': '节次',
        'range_start': '开始',
        'range_end': '结束',
        'advanced_filters': '更多条件',
        'advanced_filters_hint': '座位数与占用情况',
        'seat_min': '最少座位',
        'seat_max': '最多座位',
        'optional': '可选',
        'view_label': '查看方式',
        'view_week': '按周次',
        'view_weekday': '按星期',
        'view_period': '按节次',
        'option_search_hint': '搜索选项',
        'option_empty': '没有符合条件的选项',
        'clear_selection': '清空选择',
        'query': '查询',
        'result_idle_title': '先选择条件',
        'result_idle_hint': '完成筛选后点击查询',
        'query_failed': '查询失败',
      },
    };
  }
}

GxuEmptyClassroomQueryForm _buildForm() {
  const catalog = [
    GxuEmptyClassroomCatalogRoom(
      id: 'room-a101',
      name: 'A101',
      building: '一教',
      campusCode: '1',
      campusName: '主校区',
      availableSeats: '60',
      examSeats: '30',
      statusCode: '1',
      statusLabel: '可以使用',
    ),
  ];

  return GxuEmptyClassroomQueryForm(
    viewType: GxuEmptyClassroomViewType.period,
    selectFields: const [
      GxuEmptyClassroomSelectField(
        name: 'xqdm',
        label: '学期',
        options: [
          GxuEmptyClassroomOption(value: '2025-2026-2', label: '2026年春季'),
        ],
        selectedValues: ['2025-2026-2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'kszc',
        label: '开始周次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1周'),
          GxuEmptyClassroomOption(value: '2', label: '第2周'),
        ],
        selectedValues: ['1'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jszc',
        label: '结束周次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1周'),
          GxuEmptyClassroomOption(value: '2', label: '第2周'),
        ],
        selectedValues: ['2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'ksxq',
        label: '开始星期',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '星期一'),
          GxuEmptyClassroomOption(value: '2', label: '星期二'),
        ],
        selectedValues: ['1'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jsxq',
        label: '结束星期',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '星期一'),
          GxuEmptyClassroomOption(value: '2', label: '星期二'),
        ],
        selectedValues: ['2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'ksjc',
        label: '开始节次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1节'),
          GxuEmptyClassroomOption(value: '2', label: '第2节'),
        ],
        selectedValues: ['1'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jsjc',
        label: '结束节次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1节'),
          GxuEmptyClassroomOption(value: '2', label: '第2节'),
        ],
        selectedValues: ['2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jxlh',
        label: '教学楼',
        options: [
          GxuEmptyClassroomOption(value: '', label: '请选择'),
          GxuEmptyClassroomOption(value: '一教', label: '一教'),
        ],
        selectedValues: ['一教'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jsxxid',
        label: '教室',
        options: [
          GxuEmptyClassroomOption(value: '', label: '请选择'),
          GxuEmptyClassroomOption(value: 'room-a101', label: 'A101 · 一教'),
        ],
        selectedValues: ['room-a101'],
        isMulti: true,
      ),
      GxuEmptyClassroomSelectField(
        name: 'zyqk',
        label: '占用情况',
        options: [
          GxuEmptyClassroomOption(value: '', label: '请选择'),
          GxuEmptyClassroomOption(value: '00', label: '借用'),
        ],
        selectedValues: [],
        isMulti: true,
      ),
      GxuEmptyClassroomSelectField(
        name: 'zylx',
        label: '占用类型',
        options: [
          GxuEmptyClassroomOption(value: '', label: '请选择'),
          GxuEmptyClassroomOption(value: '1', label: '研究生占用'),
        ],
        selectedValues: [],
      ),
    ],
    textFields: [
      GxuEmptyClassroomTextField(name: 'zws', label: '座位数', value: ''),
      GxuEmptyClassroomTextField(name: 'jszws', label: '座位数', value: ''),
    ],
    classroomCatalog: catalog,
  );
}
