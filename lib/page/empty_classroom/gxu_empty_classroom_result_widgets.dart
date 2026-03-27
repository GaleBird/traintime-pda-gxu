import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';
import 'package:watermeter/page/public_widget/empty_list_view.dart';
import 'package:watermeter/repository/network_session.dart';

class GxuEmptyClassroomResultSection extends StatelessWidget {
  final GxuEmptyClassroomState state;
  final TextEditingController searchController;

  const GxuEmptyClassroomResultSection({
    super.key,
    required this.state,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final content = _ResultList(
      state: state,
      searchController: searchController,
    );
    if (state.resultError != null && state.result != null) {
      return Column(
        children: [
          _InlineStateCard(
            icon: Icons.error_outline_rounded,
            title: FlutterI18n.translate(
              context,
              "empty_classroom.query_failed",
            ),
            message: state.resultError!,
            actionLabel: FlutterI18n.translate(context, "click_to_refresh"),
            onPressed: state.refreshResults,
          ),
          const SizedBox(height: 12),
          content,
        ],
      );
    }
    return content;
  }
}

class _ResultList extends StatelessWidget {
  final GxuEmptyClassroomState state;
  final TextEditingController searchController;

  const _ResultList({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    if (state.resultState == SessionState.fetching && state.result == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final toolbar = state.result == null
        ? null
        : _ResultToolbar(state: state, searchController: searchController);
    if (state.filteredRows.isEmpty) {
      final emptyState = _buildEmptyState(context);
      if (toolbar == null) {
        return emptyState;
      }
      return Column(
        children: [toolbar, const SizedBox(height: 12), emptyState],
      );
    }
    return Column(
      children: [
        if (toolbar != null) ...[toolbar, const SizedBox(height: 12)],
        for (final row in state.visibleRows) ...[
          _ClassroomCard(row: row),
          const SizedBox(height: 12),
        ],
        if (state.hasMoreRows)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: state.loadMoreRows,
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                FlutterI18n.translate(
                  context,
                  "empty_classroom.load_more",
                  translationParams: {
                    "shown": state.visibleRows.length.toString(),
                    "total": state.totalRowCount.toString(),
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (state.resultState == SessionState.none) {
      return _HintStateCard(
        icon: Icons.tune_rounded,
        title: FlutterI18n.translate(
          context,
          "empty_classroom.result_idle_title",
        ),
        message: FlutterI18n.translate(
          context,
          "empty_classroom.result_idle_hint",
        ),
      );
    }
    if (state.resultState == SessionState.error) {
      return _InlineStateCard(
        icon: Icons.sync_problem_rounded,
        title: FlutterI18n.translate(context, "empty_classroom.query_failed"),
        message:
            state.resultError ?? FlutterI18n.translate(context, "query_failed"),
        actionLabel: FlutterI18n.translate(context, "click_to_refresh"),
        onPressed: state.refreshResults,
      );
    }
    final text = state.searchKeyword.trim().isEmpty
        ? FlutterI18n.translate(context, "empty_classroom.no_result")
        : FlutterI18n.translate(
            context,
            "empty_classroom.no_result_with_keyword",
            translationParams: {"keyword": state.searchKeyword.trim()},
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: EmptyListView(text: text, type: EmptyListViewType.reading),
    );
  }
}

class _ResultToolbar extends StatelessWidget {
  final GxuEmptyClassroomState state;
  final TextEditingController searchController;

  const _ResultToolbar({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FlutterI18n.translate(context, "empty_classroom.result_title"),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            FlutterI18n.translate(
              context,
              "empty_classroom.result_hint",
              translationParams: {
                "shown": state.visibleRows.length.toString(),
                "total": state.totalRowCount.toString(),
              },
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: (value) => state.searchKeyword = value,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: FlutterI18n.translate(
                context,
                "empty_classroom.result_search_hint",
              ),
              suffixIcon: state.searchKeyword.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => state.searchKeyword = "",
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onPressed;

  const _InlineStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _HintStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HintStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final GxuEmptyClassroomRow row;

  const _ClassroomCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (row.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          row.subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                _AvailabilityBadge(
                  availableCount: row.availableCount,
                  totalCount: row.totalCount,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              FlutterI18n.translate(context, "empty_classroom.cell_hint"),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final cell in row.cells) _StatusChip(cell: cell)],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final int availableCount;
  final int totalCount;

  const _AvailabilityBadge({
    required this.availableCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "$availableCount/$totalCount",
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GxuEmptyClassroomCell cell;

  const _StatusChip({required this.cell});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (backgroundColor, textColor) = _colorsOf(scheme, cell.state);
    return InkWell(
      onTap: cell.hasDetail ? () => _showDetailSheet(context) : null,
      borderRadius: BorderRadius.circular(16),
      child: Tooltip(
        message: "${cell.header}：${cell.value}",
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: backgroundColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cell.header,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cell.shortLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetailSheet(BuildContext context) async {
    final state = context.read<GxuEmptyClassroomState>();
    final detailFuture = state.loadCellDetail(cell);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: FutureBuilder<String>(
            future: detailFuture,
            builder: (context, snapshot) {
              return _DetailContent(cell: cell, snapshot: snapshot);
            },
          ),
        ),
      ),
    );
  }

  (Color, Color) _colorsOf(
    ColorScheme scheme,
    GxuEmptyClassroomCellState state,
  ) {
    switch (state) {
      case GxuEmptyClassroomCellState.available:
        return (
          scheme.primaryContainer.withValues(alpha: 0.78),
          scheme.onPrimaryContainer,
        );
      case GxuEmptyClassroomCellState.occupied:
        return (
          scheme.errorContainer.withValues(alpha: 0.55),
          scheme.onErrorContainer,
        );
      case GxuEmptyClassroomCellState.unavailable:
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
      case GxuEmptyClassroomCellState.unknown:
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    }
  }
}

class _DetailContent extends StatelessWidget {
  final GxuEmptyClassroomCell cell;
  final AsyncSnapshot<String> snapshot;

  const _DetailContent({required this.cell, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FlutterI18n.translate(context, "empty_classroom.detail_title"),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(cell.header, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snapshot.hasError)
            Text(snapshot.error.toString())
          else
            SelectableText(snapshot.data ?? cell.value),
        ],
      ),
    );
  }
}
