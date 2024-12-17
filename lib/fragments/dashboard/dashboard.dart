
import 'dart:math';

import 'package:fl_clash/common/common.dart';
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
  final items = [
    GridItem(
      crossAxisCellCount: 8,
      child: NetworkSpeed(),
    ),
    if (system.isDesktop) ...[
      GridItem(
        crossAxisCellCount: 4,
        child: TUNButton(),
      ),
      GridItem(
        crossAxisCellCount: 4,
        child: SystemProxyButton(),
      ),
    ],
    GridItem(
      crossAxisCellCount: 4,
      child: OutboundMode(),
    ),
    GridItem(
      crossAxisCellCount: 4,
      child: NetworkDetection(),
    ),
    GridItem(
      crossAxisCellCount: 4,
      child: TrafficUsage(),
    ),
    GridItem(
      crossAxisCellCount: 4,
      child: IntranetIP(),
    ),
  ];

  _initFab(bool isCurrent) {
    if (!isCurrent) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final commonScaffoldState =
          context.findAncestorStateOfType<CommonScaffoldState>();
      commonScaffoldState?.floatingActionButton = const StartButton();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ActiveBuilder(
      label: "dashboard",
      builder: (isCurrent, child) {
        _initFab(isCurrent);
        return child!;
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16).copyWith(
            bottom: 88,
          ),
          child: Selector<AppState, double>(
            selector: (_, appState) => appState.viewWidth,
            builder: (_, viewWidth, ___) {
              final columns = max(4 * ((viewWidth / 350).ceil()), 8);
              return SuperGrid(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: items,
                onReorder: (newIndex, oldIndex) {
                  setState(() {
                    final removeAt = items.removeAt(oldIndex);
                    items.insert(newIndex, removeAt);
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
