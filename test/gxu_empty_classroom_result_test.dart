import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';

void main() {
  group('GxuEmptyClassroomResult', () {
    test('reuses cached summaries without leaking range state', () {
      final result = _buildResult();

      final narrowRow = result
          .buildRows(
            form: _buildForm(
              viewType: GxuEmptyClassroomViewType.period,
              start: '1',
              end: '3',
            ),
          )
          .single;

      expect(narrowRow.totalCount, 3);
      expect(narrowRow.availableCount, 2);
      expect(narrowRow.occupiedCount, 1);
      expect(narrowRow.matchesKeyword('排课'), isTrue);
      expect(narrowRow.matchesKeyword('调课'), isFalse);
      expect(narrowRow.matchesKeyword('借用'), isFalse);

      final wideRow = result
          .buildRows(
            form: _buildForm(
              viewType: GxuEmptyClassroomViewType.period,
              start: '1',
              end: '5',
            ),
          )
          .single;

      expect(wideRow.totalCount, 5);
      expect(wideRow.availableCount, 2);
      expect(wideRow.occupiedCount, 3);
      expect(wideRow.matchesKeyword('排课'), isTrue);
      expect(wideRow.matchesKeyword('调课'), isTrue);
      expect(wideRow.matchesKeyword('借用'), isFalse);
      expect(wideRow.cells.map((cell) => cell.shortLabel).toList(), [
        '空闲',
        '排课',
        '空闲',
        '考试',
        '调课',
      ]);
    });

    test('buildRows summarizes slots beyond default limits', () {
      final result = _buildResult();

      final row = result
          .buildRows(
            form: _buildForm(
              viewType: GxuEmptyClassroomViewType.period,
              start: '14',
              end: '14',
            ),
          )
          .single;

      expect(row.totalCount, 1);
      expect(row.availableCount, 0);
      expect(row.occupiedCount, 1);
      expect(row.matchesKeyword('排课'), isTrue);
      expect(row.cells.single.shortLabel, '排课');
    });

    test('keeps cached summaries isolated by view type', () {
      final result = _buildResult();

      result.buildRows(
        form: _buildForm(
          viewType: GxuEmptyClassroomViewType.period,
          start: '1',
          end: '5',
        ),
      );

      final weekdayRow = result
          .buildRows(
            form: _buildForm(
              viewType: GxuEmptyClassroomViewType.weekday,
              start: '1',
              end: '2',
            ),
          )
          .single;

      expect(weekdayRow.totalCount, 2);
      expect(weekdayRow.availableCount, 0);
      expect(weekdayRow.occupiedCount, 2);
      expect(weekdayRow.matchesKeyword('排课'), isTrue);
      expect(weekdayRow.matchesKeyword('考试'), isTrue);
      expect(weekdayRow.matchesKeyword('调课'), isFalse);
      expect(weekdayRow.cells.map((cell) => cell.shortLabel).toList(), [
        '排课',
        '考试',
      ]);
    });
  });
}

GxuEmptyClassroomResult _buildResult() {
  return GxuEmptyClassroomResult(
    rooms: const [
      GxuEmptyClassroomRemoteRoom(
        roomId: 'A101',
        roomName: 'A101',
        statusCode: '1',
        availableSeats: '60',
        examSeats: '30',
        undergraduateUnavailable: false,
        schedule: {'jc2': '课程占用', 'jc14': '新增占用', 'xq1': '周一占用'},
        exam: {'jc4': '考试占用', 'xq2': '周二考试'},
        borrow: {},
        adjust: {'jc5': '调课占用'},
        other: {},
      ),
    ],
    fetchedAt: DateTime(2026, 3, 29, 12),
  );
}

GxuEmptyClassroomQueryForm _buildForm({
  required GxuEmptyClassroomViewType viewType,
  required String start,
  required String end,
}) {
  return GxuEmptyClassroomQueryForm(
    viewType: viewType,
    selectFields: switch (viewType) {
      GxuEmptyClassroomViewType.week => [
        _field(name: 'kszc', selectedValue: start),
        _field(name: 'jszc', selectedValue: end),
      ],
      GxuEmptyClassroomViewType.weekday => [
        _field(name: 'ksxq', selectedValue: start),
        _field(name: 'jsxq', selectedValue: end),
      ],
      GxuEmptyClassroomViewType.period => [
        _field(name: 'ksjc', selectedValue: start),
        _field(name: 'jsjc', selectedValue: end),
      ],
    },
    textFields: const [],
    classroomCatalog: const [],
  );
}

GxuEmptyClassroomSelectField _field({
  required String name,
  required String selectedValue,
}) {
  return GxuEmptyClassroomSelectField(
    name: name,
    label: name,
    options: const [],
    selectedValues: [selectedValue],
  );
}
