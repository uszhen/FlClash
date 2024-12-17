import 'dart:math';

import 'package:fl_clash/common/num.dart';
import 'package:fl_clash/widgets/grid.dart';
import 'package:flutter/material.dart';

typedef VoidCallback = void Function();

class SuperGrid extends StatefulWidget {
  final List<GridItem> children;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int crossAxisCount;
  final Function(int newIndex, int oldIndex)? onReorder;

  const SuperGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 1,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.onReorder,
  });

  @override
  State<SuperGrid> createState() => _SuperGridState();
}

class _SuperGridState extends State<SuperGrid> {
  List<GridItem> get children => widget.children;

  int get length => widget.children.length;
  List<BuildContext?> _itemContexts = [];
  Size _containerSize = Size.zero;
  int _targetIndex = -1;
  List<Size> _sizes = [];
  List<Offset> _offsets = [];

  List<Offset> _preTransformOffsets = [];
  final ValueNotifier<List<Offset>> _transformOffsetsNotifier =
      ValueNotifier([]);

  // final ValueNotifier<List<Tween<Offset>>> _transformOffsetsNotifier =
  //     ValueNotifier([]);

  final _dragWidgetSizeNotifier = ValueNotifier(Size.zero);
  final _dragIndexNotifier = ValueNotifier(-1);

  int get crossCount => widget.crossAxisCount;

  _initState() {
    _transformOffsetsNotifier.value = List.filled(
      length,
      Offset.zero,
    );
    _preTransformOffsets = List.from(_transformOffsetsNotifier.value);
    _sizes = List.generate(length, (index) => Size.zero);
    _offsets = [];
    _containerSize = Size.zero;
    _dragIndexNotifier.value = -1;
    _dragWidgetSizeNotifier.value = Size.zero;
  }

  @override
  void initState() {
    super.initState();
    _itemContexts = List.filled(
      length,
      null,
    );
    _initState();
  }

  Widget _wrapTransform(Widget rawChild, int index) {
    return ValueListenableBuilder(
      valueListenable: _dragIndexNotifier,
      builder: (_, index, child) {
        if (index == -1) {
          return rawChild;
        }
        return child!;
      },
      child: ValueListenableBuilder(
        valueListenable: _transformOffsetsNotifier,
        builder: (_, transformOffsets, child) {
          return TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(
              begin: _preTransformOffsets[index],
              end: transformOffsets[index],
            ),
            duration: const Duration(milliseconds: 200),
            builder: (_, offset, child) {
              return Transform.translate(
                offset: offset,
                child: child!,
              );
            },
            child: child!,
          );
        },
        child: rawChild,
      ),
    );
  }

  _handleDragStarted(int index) {
    _initState();
    _dragIndexNotifier.value = index;
    _sizes = _itemContexts.map((item) => item!.size!).toList();
    _dragWidgetSizeNotifier.value = _sizes[index];
    final parentOffset =
        (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
    _offsets = _itemContexts
        .map((item) =>
            (item!.findRenderObject() as RenderBox).localToGlobal(Offset.zero) -
            parentOffset)
        .toList();
    _containerSize = context.size!;
  }

  _handleDragEnd(DraggableDetails details) {
    if (_targetIndex == -1) {
      return;
    }
    if (widget.onReorder != null) {
      widget.onReorder!(_targetIndex, _dragIndexNotifier.value);
    }
    _initState();
  }

  _handleWill(int index) {
    final dragIndex = _dragIndexNotifier.value;
    if (dragIndex < 0 || dragIndex > _offsets.length - 1) {
      return;
    }

    final targetIndex = index;
    final indexList = List.generate(length, (i) {
      if (i == targetIndex) return _dragIndexNotifier.value;
      if (dragIndex > targetIndex && i > targetIndex && i <= dragIndex) {
        return i - 1;
      } else if (dragIndex < targetIndex && i >= dragIndex && i < targetIndex) {
        return i + 1;
      }
      return i;
    }).toList();

    List<Offset> layoutOffsets = [
      Offset(_containerSize.width, 0),
    ];
    final List<Offset> nextOffsets = [];

    for (final index in indexList) {
      final size = _sizes[index];
      final offset = _getNextOffset(layoutOffsets, size);
      final layoutOffset = Offset(
        min(
          offset.dx + size.width + widget.crossAxisSpacing,
          _containerSize.width,
        ),
        min(
          offset.dy + size.height + widget.crossAxisSpacing,
          _containerSize.height,
        ),
      );
      final startLayoutOffsetX = offset.dx;
      final endLayoutOffsetX = layoutOffset.dx;
      nextOffsets.add(offset);

      final startIndex =
          layoutOffsets.indexWhere((i) => i.dx >= startLayoutOffsetX);
      final endIndex =
          layoutOffsets.indexWhere((i) => i.dx >= endLayoutOffsetX);
      final endOffset = layoutOffsets[endIndex];

      if (startIndex != endIndex) {
        final startOffset = layoutOffsets[startIndex];
        if (startOffset.dx != startLayoutOffsetX) {
          layoutOffsets[startIndex] = Offset(
            startLayoutOffsetX,
            startOffset.dy,
          );
        }
      }
      if (endOffset.dx == endLayoutOffsetX) {
        layoutOffsets[endIndex] = layoutOffset;
      } else {
        layoutOffsets.insert(endIndex, layoutOffset);
      }
      layoutOffsets.removeRange(min(startIndex + 1, endIndex), endIndex);
    }
    _targetIndex = targetIndex;
    _preTransformOffsets = List.from(_transformOffsetsNotifier.value);
    _transformOffsetsNotifier.value = List.generate(
      length,
      (index) {
        final nextIndex = indexList.indexWhere((i) => i == index);
        return nextOffsets[nextIndex] - _offsets[index];
      },
    );
  }

  Offset _getNextOffset(List<Offset> offsets, Size size) {
    final length = offsets.length;
    Offset nextOffset = Offset(0, double.infinity);
    for (int i = 0; i < length; i++) {
      final offset = offsets[i];
      if (offset.dy.moreOrEqual(nextOffset.dy)) {
        continue;
      }
      double offsetX = 0;
      double span = 0;
      for (int j = 0;
          span < size.width &&
              j < length &&
              _containerSize.width.moreOrEqual(offsetX + size.width);
          j++) {
        final tempOffset = offsets[j];
        if (offset.dy.moreOrEqual(tempOffset.dy)) {
          span += tempOffset.dx;
          if (span >= size.width) {
            nextOffset = Offset(offsetX, offset.dy);
          }
        } else {
          offsetX += tempOffset.dx;
          span = 0;
        }
      }
    }
    return nextOffset;
  }

  Widget _wrapSizeBox(Widget child, int index) {
    return ValueListenableBuilder(
      valueListenable: _dragWidgetSizeNotifier,
      builder: (_, size, child) {
        return SizedBox.fromSize(
          size: size,
          child: child!,
        );
      },
      child: child,
    );
  }

  Widget _builderItem(int index) {
    final girdItem = children[index];
    final child = girdItem.child;
    return GridItem(
      mainAxisCellCount: girdItem.mainAxisCellCount,
      crossAxisCellCount: girdItem.crossAxisCellCount,
      child: Builder(
        builder: (context) {
          _itemContexts[index] = context;
          return Draggable(
            childWhenDragging: IgnorePointer(
              ignoring: true,
              child: _wrapTransform(
                Opacity(
                  opacity: 0.2,
                  child: _wrapSizeBox(child, index),
                ),
                index,
              ),
            ),
            data: index,
            feedback: IgnorePointer(
              ignoring: true,
              child: _wrapSizeBox(child, index),
            ),
            onDragStarted: () {
              _handleDragStarted(index);
            },
            onDragEnd: (details) {
              _handleDragEnd(details);
            },
            child: DragTarget<int>(
              builder: (_, __, ___) {
                return _wrapTransform(child, index);
              },
              onWillAcceptWithDetails: (_) {
                _handleWill(index);
                return false;
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Grid(
      axisDirection: AxisDirection.down,
      crossAxisCount: crossCount,
      crossAxisSpacing: widget.crossAxisSpacing,
      mainAxisSpacing: widget.mainAxisSpacing,
      children: [
        for (int i = 0; i < children.length; i++) _builderItem(i),
      ],
    );
  }
}
