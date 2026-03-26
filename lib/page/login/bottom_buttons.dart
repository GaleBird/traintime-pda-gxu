// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watermeter/repository/cookie_cleanup.dart';
import 'package:watermeter/repository/fork_info.dart';
import 'package:watermeter/repository/logger.dart';

class ButtomButtons extends StatelessWidget {
  final Color _bottomTextColor = const Color.fromRGBO(35, 62, 99, 0.5);
  TextStyle get _bottomTextStyle =>
      TextStyle(color: _bottomTextColor, fontWeight: FontWeight.w700);

  const ButtomButtons({super.key});

  Future<void> _openLink(
    BuildContext context, {
    required String url,
    required String errorKey,
  }) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (opened || !context.mounted) {
        return;
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
    }
    showToast(context: context, msg: FlutterI18n.translate(context, errorKey));
  }

  Future<void> _clearCookies(BuildContext context) async {
    final result = await clearAllCookies();
    if (!context.mounted) {
      return;
    }
    final message = result.hasFailures
        ? FlutterI18n.translate(
            context,
            "login.partial_clear_cache",
            translationParams: {"details": result.summary()},
          )
        : FlutterI18n.translate(context, "login.complete_clear_cache");
    showToast(context: context, msg: message);
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String labelKey,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      child: Text(
        FlutterI18n.translate(context, labelKey),
        style: _bottomTextStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 0,
      children: [
        _buildActionButton(
          context,
          labelKey: "login.clear_cache",
          onPressed: () => _clearCookies(context),
        ),
        _buildActionButton(
          context,
          labelKey: "login.see_inspector",
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TalkerScreen(talker: log),
              ),
            );
          },
        ),
        _buildActionButton(
          context,
          labelKey: 'login.official_website',
          onPressed: () => _openLink(
            context,
            url: ForkInfo.officialWebsiteUrl,
            errorKey: 'login.failed_open_official_website',
          ),
        ),
        _buildActionButton(
          context,
          labelKey: 'login.academic_system_website',
          onPressed: () => _openLink(
            context,
            url: ForkInfo.graduateSystemUrl,
            errorKey: 'login.failed_open_academic_system_website',
          ),
        ),
      ],
    );
  }
}
