import 'package:flutter/material.dart';
import 'package:watermeter/page/empty_classroom/empty_classroom_window.dart';
import 'package:watermeter/page/homepage/small_function_card.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';

class EmptyClassroomCard extends StatelessWidget {
  const EmptyClassroomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SmallFunctionCard(
      onPressed: () => context.pushReplacement(const EmptyClassroomWindow()),
      icon: Icons.meeting_room_outlined,
      nameKey: "homepage.toolbox.empty_classroom",
    );
  }
}
