import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_clash/common/common.dart';
import 'package:flutter/material.dart';

class CommonTargetIcon extends StatelessWidget {
  final String src;
  final double size;

  const CommonTargetIcon({
    super.key,
    required this.src,
    required this.size,
  });

  Widget _defaultIcon() {
    return Icon(
      IconsExt.target,
      size: size,
    );
  }

  Widget _buildIcon() {
    if (src.isEmpty) {
      return _defaultIcon();
    }
    final base64 = src.getBase64;
    if (base64 != null) {
      return Image.memory(
        base64,
        gaplessPlayback: true,
        errorBuilder: (_, error, ___) {
          return _defaultIcon();
        },
      );
    }
    return CachedNetworkImage(
      imageUrl: src,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      errorWidget: (_, __, ___) => _defaultIcon(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _buildIcon(),
    );
  }
}

class CommonIcon extends StatelessWidget {
  final IconData? iconData;
  final double size;
  final Color? color;

  const CommonIcon(
    this.iconData, {
    super.key,
    this.size = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }
}
