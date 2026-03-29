import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
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
      'gxu_empty_classroom_detail_cache_test',
    );
    network_session.supportPath = tempSupportDir;
  });

  tearDown(() async {
    if (tempSupportDir.existsSync()) {
      await tempSupportDir.delete(recursive: true);
    }
  });

  test('does not cache stale cell detail after query changes', () async {
    final detailCompleter = Completer<String>();
    var detailCalls = 0;
    final state = GxuEmptyClassroomState(
      session: _FakeEmptyClassroomSession(
        form: _buildForm(),
        onLoadCellDetail: ({required form, required cell}) {
          detailCalls++;
          if (detailCalls == 1) {
            return detailCompleter.future;
          }
          return Future.value('fresh-detail');
        },
      ),
    );

    await state.initialize();

    const cell = GxuEmptyClassroomCell(
      header: 'P1',
      value: 'occupied 1',
      roomId: 'room-a101',
      slotNumber: 1,
      viewType: GxuEmptyClassroomViewType.period,
      state: GxuEmptyClassroomCellState.occupied,
      localDetailMessage: null,
    );

    final pendingDetail = state.loadCellDetail(cell);
    state.updateSelect('ksjc', ['2']);
    detailCompleter.complete('stale-detail');

    expect(await pendingDetail, 'stale-detail');
    expect(await state.loadCellDetail(cell), 'fresh-detail');
    expect(detailCalls, 2);
  });
}

typedef _LoadCellDetail =
    Future<String> Function({
      required GxuEmptyClassroomQueryForm form,
      required GxuEmptyClassroomCell cell,
    });

class _FakeEmptyClassroomSession extends GxuEmptyClassroomSession {
  final GxuEmptyClassroomQueryForm form;
  final _LoadCellDetail onLoadCellDetail;

  _FakeEmptyClassroomSession({
    required this.form,
    required this.onLoadCellDetail,
  });

  @override
  Future<GxuEmptyClassroomQueryForm> loadQueryForm() async => form;

  @override
  Future<String> loadCellDetail({
    required GxuEmptyClassroomQueryForm form,
    required GxuEmptyClassroomCell cell,
  }) {
    return onLoadCellDetail(form: form, cell: cell);
  }
}

GxuEmptyClassroomQueryForm _buildForm() {
  return const GxuEmptyClassroomQueryForm(
    viewType: GxuEmptyClassroomViewType.period,
    selectFields: [
      GxuEmptyClassroomSelectField(
        name: 'ksjc',
        label: 'Start',
        options: [
          GxuEmptyClassroomOption(value: '1', label: 'P1'),
          GxuEmptyClassroomOption(value: '2', label: 'P2'),
        ],
        selectedValues: ['1'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jsjc',
        label: 'End',
        options: [
          GxuEmptyClassroomOption(value: '1', label: 'P1'),
          GxuEmptyClassroomOption(value: '2', label: 'P2'),
        ],
        selectedValues: ['2'],
      ),
    ],
    textFields: [],
    classroomCatalog: [],
  );
}
