import 'dart:math';

import 'package:fl_clash/common/num.dart';
import 'package:fl_clash/widgets/grid.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReorderableGrid extends StatefulWidget {
  final List<GridItem> children;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int crossAxisCount;

  // final AxisDirection axisDirection;

  const ReorderableGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 1,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    // this.axisDirection = AxisDirection.down,
  });

  @override
  State<ReorderableGrid> createState() => _ReorderableGridState();
}

class _ReorderableGridState extends State<ReorderableGrid> {
  List<GridItem> get children => widget.children;
  List<BuildContext?> _itemContexts = [];
  Size _containerSize = Size.zero;
  List<int> _indexList = [];
  List<Size> _sizes = [];
  List<Offset> _offsets = [];
  List<Offset> _preTransformOffsets = [];
  List<Offset> _transformOffsets = [];
  Widget? _dragWidget;
  Size _dragWidgetSize = Size.zero;
  int _dragIndex = -1;

  int get crossCount => widget.crossAxisCount;

  @override
  void initState() {
    super.initState();
    _transformOffsets = List.filled(children.length, Offset.zero);
    _preTransformOffsets = _transformOffsets;
    _indexList = List.generate(children.length, (index) => index);
    _sizes = List.generate(children.length, (index) => Size.zero);
    _itemContexts = List.filled(
      children.length,
      null,
    );
  }

  Widget _wrapTransform(Widget child, int index) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(
        begin: _preTransformOffsets[index],
        end: _transformOffsets[index],
      ),
      duration: const Duration(milliseconds: 200),
      builder: (_, offset, child) {
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: child,
    );
  }

  _handleDragStarted(int index) {
    _dragIndex = index;
    _sizes = _itemContexts.map((item) => item!.size!).toList();
    _dragWidgetSize = _sizes[index];
    _dragWidget = children[index].child;
    final parentOffset =
        (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
    _offsets = _itemContexts
        .map((item) =>
            (item!.findRenderObject() as RenderBox).localToGlobal(Offset.zero) -
            parentOffset)
        .toList();
    _transformOffsets = List.filled(children.length, Offset.zero);
    _indexList = List.generate(children.length, (index) => index);
    _containerSize = context.size!;
  }

  _handleWill(int index) {
    if (_dragIndex < 0 || _dragIndex > _offsets.length - 1) {
      return;
    }
    final targetIndex = _indexList[index];
    _indexList = _indexList.map((i) {
      if (i == targetIndex) return _dragIndex;
      if (_dragIndex > targetIndex && i > targetIndex && i <= _dragIndex) {
        return i - 1;
      }
      if (_dragIndex < targetIndex && i >= _dragIndex && i < targetIndex) {
        return i + 1;
      }
      return i;
    }).toList();
    List<Offset> layoutOffsets = [
      Offset(_containerSize.width, 0),
    ];
    final List<Offset> nextOffsets = [];
    print(_indexList);
    for (final index in _indexList) {
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
      print(
          "offset ==> $offset layoutOffset ===> $layoutOffset, startIndex ===> $startIndex, endIndex ===> $endIndex");
      print("layoutOffsets ===> $layoutOffsets");
    }
    _preTransformOffsets = List.from(_transformOffsets);
    _transformOffsets = List.generate(
      _indexList.length,
      (index) {
        final nextIndex = _indexList.indexWhere((i) => i == index);
        return nextOffsets[nextIndex] - _offsets[index];
      },
    );

    _dragIndex = targetIndex;
    setState(() {});
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
      // && offsets[j].dx >= size.width - span;
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

  Widget _builder(int index) {
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
              child: Opacity(
                opacity: 0.2,
                child: SizedBox(
                  width: _dragWidgetSize.width,
                  height: _dragWidgetSize.height,
                  child: _wrapTransform(
                    child,
                    index,
                  ),
                ),
              ),
            ),
            data: index,
            feedback: Builder(
              builder: (_) {
                return IgnorePointer(
                  ignoring: true,
                  child: SizedBox(
                    width: _dragWidgetSize.width,
                    height: _dragWidgetSize.height,
                    child: _dragWidget,
                  ),
                );
              },
            ),
            onDragCompleted: () {},
            onDragStarted: () {
              _handleDragStarted(index);
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
        for (int i = 0; i < children.length; i++) _builder(i),
      ],
    );
  }
}
