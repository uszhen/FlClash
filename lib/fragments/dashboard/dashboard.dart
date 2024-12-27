import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/fragments/dashboard/widgets/status_button.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/intranet_ip.dart';
import 'widgets/network_detection.dart';
import 'widgets/network_speed.dart';
import 'widgets/outbound_mode.dart';
import 'widgets/start_button.dart';
import 'widgets/traffic_usage.dart';

class DashboardFragment extends StatefulWidget {
  const DashboardFragment({super.key});

  @override
  State<DashboardFragment> createState() => _DashboardFragmentState();
}

class _DashboardFragmentState extends State<DashboardFragment> {
  final key = GlobalKey<SuperGridState>();

  _initScaffold(bool isCurrent) {
    if (!isCurrent) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final commonScaffoldState =
          context.findAncestorStateOfType<CommonScaffoldState>();
      commonScaffoldState?.floatingActionButton = const StartButton();
      commonScaffoldState?.actions = [
        IconButton(
          icon: ValueListenableBuilder(
            valueListenable: key.currentState!.isEditNotifier,
            builder: (_, isEdit, ___) {
              return isEdit
                  ? Icon(Icons.save)
                  : Icon(
                      Icons.edit,
                    );
            },
          ),
          onPressed: () {
            key.currentState!.isEditNotifier.value =
                !key.currentState!.isEditNotifier.value;
          },
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ActiveBuilder(
      label: "dashboard",
      builder: (isCurrent, child) {
        _initScaffold(isCurrent);
        return child!;
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16).copyWith(
            bottom: 88,
          ),
          child: Selector2<AppState, Config, DashboardState>(
            selector: (_, appState, config) => DashboardState(
              dashboardWidgets: config.appSetting.dashboardWidgets,
              viewWidth: appState.viewWidth,
            ),
            builder: (_, state, ___) {
              final columns = max(4 * ((state.viewWidth / 350).ceil()), 8);
              return SuperGrid(
                key: key,
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: state.dashboardWidgets
                    .where(
                      (item) => item.platforms.contains(
                        SupportPlatform.currentPlatform,
                      ),
                    )
                    .map(
                      (item) => item.widget,
                    )
                    .toList(),
                onSave: (_) {},
              );
            },
          ),
        ),
      ),
    );
  }
}
