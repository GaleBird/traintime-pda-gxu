import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_page.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/repository/network_session.dart';

class EmptyClassroomWindow extends StatelessWidget {
  const EmptyClassroomWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GxuEmptyClassroomState()..initialize(),
      child: Consumer<GxuEmptyClassroomState>(
        builder: (context, state, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                FlutterI18n.translate(context, "empty_classroom.title"),
              ),
              actions: [
                if (state.canRefresh && state.result != null)
                  IconButton(
                    icon: const Icon(Icons.replay_outlined),
                    onPressed: state.resultState == SessionState.fetching
                        ? null
                        : state.refreshResults,
                  ),
              ],
            ),
            body: Builder(
              builder: (context) {
                switch (state.pageState) {
                  case SessionState.fetching:
                    return const Center(child: CircularProgressIndicator());
                  case SessionState.error:
                    return ReloadWidget(
                      errorStatus: state.pageError,
                      function: state.reloadForm,
                    );
                  case SessionState.fetched:
                    return const GxuEmptyClassroomPage();
                  case SessionState.none:
                    return const SizedBox.shrink();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
