import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IntranetIP extends StatelessWidget {
  const IntranetIP({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      info: Info(
        label: appLocalizations.intranetIP,
        iconData: Icons.devices,
      ),
      onPressed: () {},
      child: Container(
        padding: const EdgeInsets.all(16).copyWith(top: 0),
        height: globalState.measure.titleMediumHeight + 24 - 2,
        child: Selector<AppFlowingState, String?>(
          selector: (_, appFlowingState) => appFlowingState.localIp,
          builder: (_, value, __) {
            return FadeBox(
              child: value != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    flex: 1,
                    child: TooltipText(
                      text: Text(
                        value.isNotEmpty
                            ? value
                            : appLocalizations.noNetwork,
                        style: context
                            .textTheme.titleLarge?.toSoftBold.toMinus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
                  : const Padding(
                padding: EdgeInsets.all(2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
