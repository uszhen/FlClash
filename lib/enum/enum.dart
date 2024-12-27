// ignore_for_file: constant_identifier_names

import 'package:fl_clash/fragments/dashboard/widgets/widgets.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

enum GroupType { Selector, URLTest, Fallback, LoadBalance, Relay }

enum GroupName { GLOBAL, Proxy, Auto, Fallback }

extension GroupTypeExtension on GroupType {
  static List<String> get valueList => GroupType.values
      .map(
        (e) => e.toString().split(".").last,
      )
      .toList();

  bool get isURLTestOrFallback {
    return [GroupType.URLTest, GroupType.Fallback].contains(this);
  }

  static GroupType? getGroupType(String value) {
    final index = GroupTypeExtension.valueList.indexOf(value);
    if (index == -1) return null;
    return GroupType.values[index];
  }

  String get value => GroupTypeExtension.valueList[index];
}

enum UsedProxy { GLOBAL, DIRECT, REJECT }

extension UsedProxyExtension on UsedProxy {
  static List<String> get valueList => UsedProxy.values
      .map(
        (e) => e.toString().split(".").last,
      )
      .toList();

  String get value => UsedProxyExtension.valueList[index];
}

enum Mode { rule, global, direct }

enum ViewMode { mobile, laptop, desktop }

enum LogLevel { debug, info, warning, error, silent }

enum TransportProtocol { udp, tcp }

enum TrafficUnit { B, KB, MB, GB, TB }

enum NavigationItemMode { mobile, desktop, more }

enum Network { tcp, udp }

enum ProxiesSortType { none, delay, name }

enum TunStack { gvisor, system, mixed }

enum AccessControlMode { acceptSelected, rejectSelected }

enum AccessSortType { none, name, time }

enum ProfileType { file, url }

enum ResultType { success, error }

enum AppMessageType {
  log,
  delay,
  request,
  started,
  loaded,
}

enum ServiceMessageType {
  protect,
  process,
  started,
  loaded,
}

enum FindProcessMode { always, off }

enum RecoveryOption {
  all,
  onlyProfiles,
}

enum ChipType { action, delete }

enum CommonCardType { plain, filled }
//
// extension CommonCardTypeExt on CommonCardType {
//   CommonCardType get variant => CommonCardType.plain;
// }

enum ProxiesType { tab, list }

enum ProxiesLayout { loose, standard, tight }

enum ProxyCardType { expand, shrink, min }

enum DnsMode {
  normal,
  @JsonValue("fake-ip")
  fakeIp,
  @JsonValue("redir-host")
  redirHost,
  hosts
}

enum KeyboardModifier {
  alt([
    PhysicalKeyboardKey.altLeft,
    PhysicalKeyboardKey.altRight,
  ]),
  capsLock([
    PhysicalKeyboardKey.capsLock,
  ]),
  control([
    PhysicalKeyboardKey.controlLeft,
    PhysicalKeyboardKey.controlRight,
  ]),
  fn([
    PhysicalKeyboardKey.fn,
  ]),
  meta([
    PhysicalKeyboardKey.metaLeft,
    PhysicalKeyboardKey.metaRight,
  ]),
  shift([
    PhysicalKeyboardKey.shiftLeft,
    PhysicalKeyboardKey.shiftRight,
  ]);

  final List<PhysicalKeyboardKey> physicalKeys;

  const KeyboardModifier(this.physicalKeys);
}

extension KeyboardModifierExt on KeyboardModifier {
  HotKeyModifier toHotKeyModifier() {
    return switch (this) {
      KeyboardModifier.alt => HotKeyModifier.alt,
      KeyboardModifier.capsLock => HotKeyModifier.capsLock,
      KeyboardModifier.control => HotKeyModifier.control,
      KeyboardModifier.fn => HotKeyModifier.fn,
      KeyboardModifier.meta => HotKeyModifier.meta,
      KeyboardModifier.shift => HotKeyModifier.shift,
    };
  }
}

enum HotAction {
  start,
  view,
  mode,
  proxy,
  tun,
}

enum ProxiesIconStyle {
  standard,
  none,
  icon,
}

enum FontFamily {
  system(),
  miSans("MiSans"),
  twEmoji("Twemoji"),
  icon("Icons");

  final String? value;

  const FontFamily([this.value]);
}

enum RouteMode {
  bypassPrivate,
  config,
}

enum ActionMethod {
  message,
  initClash,
  getIsInit,
  forceGc,
  shutdown,
  validateConfig,
  updateConfig,
  getProxies,
  changeProxy,
  getTraffic,
  getTotalTraffic,
  resetTraffic,
  asyncTestDelay,
  getConnections,
  closeConnections,
  closeConnection,
  getExternalProviders,
  getExternalProvider,
  updateGeoData,
  updateExternalProvider,
  sideLoadExternalProvider,
  startLog,
  stopLog,
  startListener,
  stopListener,
}

enum AuthorizeCode { none, success, error }

enum WindowsHelperServiceStatus {
  none,
  presence,
  running,
}

enum DebounceTag {
  updateClashConfig,
  updateGroups,
  addCheckIpNum,
  applyProfile,
  savePreferences,
  changeProxy,
  checkIp,
  handleWill,
  updateDelay,
  vpnTip,
  autoLaunch
}

enum DashboardWidget {
  networkSpeed(
    GridItem(
      crossAxisCellCount: 8,
      child: NetworkSpeed(),
    ),
  ),
  outboundMode(
    GridItem(
      crossAxisCellCount: 4,
      child: OutboundMode(),
    ),
  ),
  trafficUsage(
    GridItem(
      crossAxisCellCount: 4,
      child: TrafficUsage(),
    ),
  ),
  networkDetection(
    GridItem(
      crossAxisCellCount: 4,
      child: NetworkDetection(),
    ),
  ),
  tunButton(
    GridItem(
      crossAxisCellCount: 4,
      child: TUNButton(),
    ),
  ),
  systemProxyButton(
    GridItem(
      crossAxisCellCount: 4,
      child: SystemProxyButton(),
    ),
  ),
  intranetIp(
    GridItem(
      crossAxisCellCount: 4,
      child: IntranetIP(),
    ),
  );

  final Widget widget;

  const DashboardWidget(this.widget);
}
