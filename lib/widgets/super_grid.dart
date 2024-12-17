import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/widgets/card.dart';
import 'package:fl_clash/widgets/grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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

class _SuperGridState extends State<SuperGrid>
    with SingleTickerProviderStateMixin {
  List<GridItem> get children => widget.children;

  int get length => widget.children.length;
  List<BuildContext?> _itemContexts = [];
  Size _containerSize = Size.zero;
  int _targetIndex = -1;
  Offset _targetOffset = Offset.zero;
  List<Size> _sizes = [];
  List<Offset> _offsets = [];
  Offset _parentOffset = Offset.zero;
  Function? _handleWillDebounce;

  final ValueNotifier<List<Tween<Offset>>> _transformTweenListNotifier =
      ValueNotifier([]);

  final ValueNotifier<bool> _animating = ValueNotifier(false);

  final _dragWidgetSizeNotifier = ValueNotifier(Size.zero);
  final _dragIndexNotifier = ValueNotifier(-1);

  late AnimationController _controller;
  Animation<Offset>? _fakeDragWidgetAnimation;

  int get crossCount => widget.crossAxisCount;

  _initState() {
    _transformTweenListNotifier.value = List.filled(
      length,
      Tween(
        begin: Offset.zero,
        end: Offset.zero,
      ),
    );
    _sizes = List.generate(length, (index) => Size.zero);
    _offsets = [];
    _containerSize = Size.zero;
    _dragIndexNotifier.value = -1;
    _dragWidgetSizeNotifier.value = Size.zero;
    _targetOffset = Offset.zero;
    _parentOffset = Offset.zero;
  }

  @override
  void initState() {
    super.initState();
    _itemContexts = List.filled(
      length,
      null,
    );
    _controller = AnimationController.unbounded(
      vsync: this,
      duration: commonDuration,
    );
    _initState();
  }

  Widget _wrapTransform(Widget rawChild, int index) {
    return ValueListenableBuilder(
      valueListenable: _animating,
      builder: (_, animating, child) {
        if (animating) {
          if (_targetIndex == index) {
            return _sizeBoxWrap(
              Container(),
              index,
            );
          }
          return rawChild;
        }
        return child!;
      },
      child: ValueListenableBuilder(
        valueListenable: _dragIndexNotifier,
        builder: (_, dragIndex, child) {
          if (dragIndex == -1) {
            return rawChild;
          }
          return child!;
        },
        child: ValueListenableBuilder(
          valueListenable: _transformTweenListNotifier,
          builder: (_, transformTweenList, child) {
            return TweenAnimationBuilder<Offset>(
              tween: Tween(
                begin: transformTweenList[index].begin,
                end: transformTweenList[index].end,
              ),
              curve: Curves.easeInOut,
              duration: commonDuration,
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
      ),
    );
  }

  _handleDragStarted(int index) {
    _initState();
    _dragIndexNotifier.value = index;
    _sizes = _itemContexts.map((item) => item!.size!).toList();
    _dragWidgetSizeNotifier.value = _sizes[index];
    _parentOffset =
        (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
    _offsets = _itemContexts
        .map((item) =>
            (item!.findRenderObject() as RenderBox).localToGlobal(Offset.zero) -
            _parentOffset)
        .toList();
    _targetIndex = index;
    _targetOffset = _offsets[index];
    _containerSize = context.size!;
  }

  _handleDragEnd(DraggableDetails details) async {
    if (_targetIndex == -1) {
      return;
    }
    if (widget.onReorder != null) {
      widget.onReorder!(_targetIndex, _dragIndexNotifier.value);
    }
    _transformTweenListNotifier.value = List.filled(
      length,
      Tween(
        begin: Offset.zero,
        end: Offset.zero,
      ),
    );
    const spring = SpringDescription(
      mass: 1,
      stiffness: 100,
      damping: 10,
    );
    final simulation = SpringSimulation(spring, 0, 1, 0);

    _fakeDragWidgetAnimation = Tween(
      begin: details.offset - _parentOffset,
      end: _targetOffset,
    ).animate(_controller);
    _animating.value = true;
    await _controller.animateWith(simulation);
    // await Future.delayed(Duration(milliseconds: 300));
    _animating.value = false;
    _fakeDragWidgetAnimation = null;
    _initState();
  }

  _handleWill(int index) async {
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
      print(
          "offset ==> $offset layoutOffset ===> $layoutOffset, startIndex ===> $startIndex, endIndex ===> $endIndex");
      print("layoutOffsets ===> $layoutOffsets");
    }
    _targetIndex = targetIndex;
    _targetOffset = nextOffsets[targetIndex];
    _transformTweenListNotifier.value = List.generate(
      length,
      (index) {
        final nextIndex = indexList.indexWhere((i) => i == index);
        final offset = nextOffsets[nextIndex] - _offsets[index];
        return Tween(
          begin: _transformTweenListNotifier.value[index].begin,
          end: offset,
        );
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
          span = tempOffset.dx - offsetX;
          if (span >= size.width) {
            nextOffset = Offset(offsetX, offset.dy);
          }
        } else {
          offsetX = tempOffset.dx;
          span = 0;
        }
      }
    }
    return nextOffset;
  }

  Widget _sizeBoxWrap(Widget child, int index) {
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

  Widget _ignoreWrap(Widget child) {
    return ValueListenableBuilder(
      valueListenable: _animating,
      builder: (_, animating, child) {
        if (animating) {
          return IgnorePointer(
            ignoring: true,
            child: child!,
          );
        } else {
          return child!;
        }
      },
      child: child,
    );
  }

  Widget _draggableWrap({
    required Widget childWhenDragging,
    required Widget feedback,
    required Widget target,
    required int index,
  }) {
    if (system.isDesktop) {
      return Draggable(
        childWhenDragging: childWhenDragging,
        data: index,
        feedback: feedback,
        onDragStarted: () {
          _handleDragStarted(index);
        },
        onDragEnd: (details) {
          _handleDragEnd(details);
        },
        child: target,
      );
    }
    return LongPressDraggable(
      childWhenDragging: childWhenDragging,
      data: index,
      feedback: feedback,
      onDragStarted: () {
        _handleDragStarted(index);
      },
      onDragEnd: (details) {
        _handleDragEnd(details);
      },
      child: target,
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
          final childWhenDragging = IgnorePointer(
            ignoring: true,
            child: _wrapTransform(
              Opacity(
                opacity: 0.2,
                child: _sizeBoxWrap(
                  CommonCard(
                    child: Container(
                      color: context.colorScheme.primary,
                    ),
                  ),
                  index,
                ),
              ),
              index,
            ),
          );
          final feedback = IgnorePointer(
            ignoring: true,
            child: _sizeBoxWrap(
              CommonCard(
                child: Material(
                  elevation: 6,
                  child: child,
                ),
              ),
              index,
            ),
          );
          final target = DragTarget<int>(
            builder: (_, __, ___) {
              return _wrapTransform(child, index);
            },
            onWillAcceptWithDetails: (_) {
              _handleWillDebounce ??= debounce(_handleWill);
              _handleWillDebounce!([index]);
              return false;
            },
          );
          return _draggableWrap(
            childWhenDragging: childWhenDragging,
            feedback: feedback,
            target: target,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildFakeTransformWidget() {
    return ValueListenableBuilder<bool>(
      valueListenable: _animating,
      builder: (_, animating, __) {
        final index = _targetIndex;
        if (!animating || _fakeDragWidgetAnimation == null || index == -1) {
          return Container();
        }
        return _sizeBoxWrap(
          AnimatedBuilder(
            animation: _fakeDragWidgetAnimation!,
            builder: (_, child) {
              return Transform.translate(
                offset: _fakeDragWidgetAnimation!.value,
                child: child!,
              );
            },
            child: IgnorePointer(
              ignoring: true,
              child: children[index].child,
            ),
          ),
          index,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ignoreWrap(
          Grid(
            axisDirection: AxisDirection.down,
            crossAxisCount: crossCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
            children: [
              for (int i = 0; i < children.length; i++) _builderItem(i),
            ],
          ),
        ),
        _buildFakeTransformWidget(),
      ],
    );
  }
}
