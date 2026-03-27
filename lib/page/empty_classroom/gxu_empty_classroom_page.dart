import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_panels.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_result_widgets.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';

class GxuEmptyClassroomPage extends StatefulWidget {
  const GxuEmptyClassroomPage({super.key});

  @override
  State<GxuEmptyClassroomPage> createState() => _GxuEmptyClassroomPageState();
}

class _GxuEmptyClassroomPageState extends State<GxuEmptyClassroomPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GxuEmptyClassroomState>();
    final form = state.form;
    if (form == null) {
      return const SizedBox.shrink();
    }
    _syncSearchController(state.searchKeyword);
    return RefreshIndicator(
      onRefresh: state.refreshResults,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              GxuEmptyClassroomFilterPanel(form: form, state: state),
              if (state.result != null) ...[
                const SizedBox(height: 12),
                GxuEmptyClassroomOverviewPanel(state: state, form: form),
              ],
              const SizedBox(height: 12),
              GxuEmptyClassroomResultSection(
                state: state,
                searchController: _searchController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncSearchController(String value) {
    if (_searchController.text == value) {
      return;
    }
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
