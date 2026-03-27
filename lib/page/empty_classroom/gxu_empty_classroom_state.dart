import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/repository/gxu_ids/gxu_empty_classroom_session.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class GxuEmptyClassroomState extends ChangeNotifier {
  static const _initialVisibleRowCount = 40;
  static const _visibleRowBatchSize = 40;

  final GxuEmptyClassroomSession session;

  bool _disposed = false;
  SessionState pageState = SessionState.fetching;
  SessionState resultState = SessionState.none;
  GxuEmptyClassroomQueryForm? form;
  GxuEmptyClassroomResult? result;
  String? pageError;
  String? resultError;
  String _searchKeyword = "";
  int _visibleRowCount = _initialVisibleRowCount;
  List<GxuEmptyClassroomRow> _baseRows = const [];
  List<GxuEmptyClassroomRow> _filteredRows = const [];
  final Map<String, String> _detailCache = {};

  GxuEmptyClassroomState({GxuEmptyClassroomSession? session})
    : session = session ?? GxuEmptyClassroomSession();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> initialize() async {
    pageState = SessionState.fetching;
    resultState = SessionState.none;
    result = null;
    pageError = null;
    resultError = null;
    notifyListeners();
    try {
      form = _restoreQueryForm(await session.loadQueryForm());
      _rebuildRows(resetVisibleCount: true);
      pageState = SessionState.fetched;
      notifyListeners();
    } catch (error, stackTrace) {
      log.error(
        "[GxuEmptyClassroomState] Failed to initialize query page.",
        error,
        stackTrace,
      );
      pageState = SessionState.error;
      pageError = error.toString();
      notifyListeners();
    }
  }

  Future<void> reloadForm() => initialize();

  Future<void> refreshResults() async {
    final currentForm = form;
    if (currentForm == null) {
      return;
    }
    resultState = SessionState.fetching;
    resultError = null;
    notifyListeners();
    try {
      result = await session.search(currentForm);
      _detailCache.clear();
      _rebuildRows(resetVisibleCount: true);
      resultState = SessionState.fetched;
      _persistForm(currentForm);
    } catch (error, stackTrace) {
      log.error(
        "[GxuEmptyClassroomState] Failed to query empty classroom.",
        error,
        stackTrace,
      );
      resultState = SessionState.error;
      resultError = error.toString();
    }
    notifyListeners();
  }

  Future<String> loadCellDetail(GxuEmptyClassroomCell cell) {
    final currentForm = form;
    if (currentForm == null) {
      throw StateError("GxuEmptyClassroomState.form is null.");
    }
    final cacheKey = _detailCacheKey(cell);
    final cached = _detailCache[cacheKey];
    if (cached != null) {
      return SynchronousFuture(cached);
    }
    return session.loadCellDetail(form: currentForm, cell: cell).then((value) {
      _detailCache[cacheKey] = value;
      return value;
    });
  }

  void updateSelect(String name, List<String> values) {
    final currentForm = form;
    if (currentForm == null) {
      return;
    }
    form = currentForm.updateSelect(name, values);
    _persistForm(form!);
    notifyListeners();
  }

  void updateText(String name, String value) {
    final currentForm = form;
    if (currentForm == null) {
      return;
    }
    form = currentForm.updateText(name, value);
    _persistForm(form!);
    notifyListeners();
  }

  void updateViewType(GxuEmptyClassroomViewType value) {
    final currentForm = form;
    if (currentForm == null || currentForm.viewType == value) {
      return;
    }
    form = currentForm.updateViewType(value);
    _rebuildRows(resetVisibleCount: true);
    _persistForm(form!);
    notifyListeners();
  }

  set searchKeyword(String value) {
    if (_searchKeyword == value) {
      return;
    }
    _searchKeyword = value;
    _applySearchFilter(resetVisibleCount: true);
    notifyListeners();
  }

  String get searchKeyword => _searchKeyword;

  List<GxuEmptyClassroomRow> get filteredRows => _filteredRows;

  List<GxuEmptyClassroomRow> get visibleRows {
    if (_filteredRows.length <= _visibleRowCount) {
      return _filteredRows;
    }
    return _filteredRows.sublist(0, _visibleRowCount);
  }

  bool get hasMoreRows => _visibleRowCount < _filteredRows.length;

  int get totalRowCount => _filteredRows.length;

  int get visibleAvailableSlotCount {
    return _filteredRows.fold(0, (sum, row) => sum + row.availableCount);
  }

  bool get canRefresh => form != null && pageState == SessionState.fetched;

  void loadMoreRows() {
    if (!hasMoreRows) {
      return;
    }
    _visibleRowCount = math.min(
      _filteredRows.length,
      _visibleRowCount + _visibleRowBatchSize,
    );
    notifyListeners();
  }

  GxuEmptyClassroomQueryForm _restoreQueryForm(
    GxuEmptyClassroomQueryForm value,
  ) {
    final restored = value.restoreFromPreference(
      preference.getString(preference.Preference.gxuEmptyClassroomQuery),
    );
    final buildingChoice = preference.getString(
      preference.Preference.emptyClassroomLastChoice,
    );
    if (buildingChoice.isEmpty) {
      return restored;
    }
    for (final field in restored.selectFields) {
      if (gxuLooksLikeBuildingField(field) &&
          field.containsOption(buildingChoice)) {
        return restored.updateSelect(field.name, [buildingChoice]);
      }
    }
    return restored;
  }

  void _persistForm(GxuEmptyClassroomQueryForm value) {
    final payload = jsonEncode(value.toPreferenceJson());
    unawaited(
      preference.setString(
        preference.Preference.gxuEmptyClassroomQuery,
        payload,
      ),
    );
    for (final field in value.selectFields) {
      if (gxuLooksLikeBuildingField(field)) {
        unawaited(
          preference.setString(
            preference.Preference.emptyClassroomLastChoice,
            field.selectedValue,
          ),
        );
        return;
      }
    }
  }

  void _rebuildRows({required bool resetVisibleCount}) {
    final currentForm = form;
    final currentResult = result;
    if (currentForm == null || currentResult == null) {
      _baseRows = const [];
      _filteredRows = const [];
      _visibleRowCount = _initialVisibleRowCount;
      return;
    }
    _baseRows = currentResult.buildRows(form: currentForm);
    _applySearchFilter(resetVisibleCount: resetVisibleCount);
  }

  void _applySearchFilter({required bool resetVisibleCount}) {
    _filteredRows = _baseRows
        .where((row) => row.matchesKeyword(_searchKeyword))
        .toList(growable: false);
    if (resetVisibleCount) {
      _visibleRowCount = math.min(
        _filteredRows.length,
        _initialVisibleRowCount,
      );
    } else if (_visibleRowCount > _filteredRows.length) {
      _visibleRowCount = _filteredRows.length;
    }
  }

  String _detailCacheKey(GxuEmptyClassroomCell cell) {
    return "${cell.viewType.preferenceValue}:${cell.roomId}:${cell.slotNumber}";
  }
}
