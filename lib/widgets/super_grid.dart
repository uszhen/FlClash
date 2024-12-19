import 'dart:async';
import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
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
  final bool isEdit;

  const SuperGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 1,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.isEdit = false,
  });

  @override
  State<SuperGrid> createState() => SuperGridState();
}

class SuperGridState extends State<SuperGrid> with TickerProviderStateMixin {
  final ValueNotifier<List<GridItem>> _childrenNotifier = ValueNotifier([]);

  int get length => _childrenNotifier.value.length;
  List<int> _tempIndexList = [];
  List<BuildContext?> _itemContexts = [];
  Size _containerSize = Size.zero;
  int _targetIndex = -1;
  Offset _targetOffset = Offset.zero;
  List<Size> _sizes = [];
  List<Offset> _offsets = [];
  Offset _parentOffset = Offset.zero;
  EdgeDraggingAutoScroller? _edgeDraggingAutoScroller;
  final ValueNotifier<bool> isEditNotifier = ValueNotifier(false);

  final ValueNotifier<Map<int, Tween<Offset>>> _transformTweenMapNotifier =
      ValueNotifier({});

  final ValueNotifier<bool> _animating = ValueNotifier(false);

  final _dragWidgetSizeNotifier = ValueNotifier(Size.zero);
  final _dragIndexNotifier = ValueNotifier(-1);

  late AnimationController _fakeDragWidgetController;
  Animation<Offset>? _fakeDragWidgetAnimation;

  late AnimationController _controller;
  late Animation<double> _animation;
  Rect _dragRect = Rect.zero;
  Scrollable? _scrollable;

  int get crossCount => widget.crossAxisCount;

  _initTransformState() {
    _sizes = _itemContexts.map((item) => item!.size!).toList();
    _parentOffset =
        (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
    _offsets = _itemContexts
        .map((item) =>
            (item!.findRenderObject() as RenderBox).localToGlobal(Offset.zero) -
            _parentOffset)
        .toList();
    _containerSize = context.size!;
  }

  _initState() {
    _sizes = List.generate(length, (index) => Size.zero);
    _offsets = [];
    _containerSize = Size.zero;
    _dragIndexNotifier.value = -1;
    _dragWidgetSizeNotifier.value = Size.zero;
    _targetOffset = Offset.zero;
    _parentOffset = Offset.zero;
    _dragRect = Rect.zero;
  }

  @override
  void initState() {
    super.initState();
    isEditNotifier.value = widget.isEdit;
    _childrenNotifier.value = widget.children;
    _fakeDragWidgetController = AnimationController.unbounded(
      vsync: this,
      duration: commonDuration,
    );
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -0.012,
      end: 0.018,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final scrollable = context.findAncestorWidgetOfExactType<Scrollable>();
    if (scrollable == null) {
      return;
    }
    if (_scrollable != scrollable) {
      _edgeDraggingAutoScroller = EdgeDraggingAutoScroller(
        Scrollable.of(context),
        onScrollViewScrolled: () {
          _edgeDraggingAutoScroller?.startAutoScrollIfNecessary(_dragRect);
        },
        velocityScalar: 40,
      );
    }
  }

  @override
  void didUpdateWidget(SuperGrid oldWidget) {
    if (widget.isEdit != oldWidget.isEdit) {
      isEditNotifier.value = widget.isEdit;
    }
    super.didUpdateWidget(oldWidget);
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
        valueListenable: _transformTweenMapNotifier,
        builder: (_, transformTweenMap, child) {
          final tween = transformTweenMap[index];
          if (tween == null) {
            return Transform.translate(
              offset: Offset.zero,
              child: SizedBox(
                width: _sizes[index].width,
                height: _sizes[index].height,
              ),
            );
          }
          return TweenAnimationBuilder<Offset>(
            tween: Tween(
              begin: tween.begin,
              end: tween.end,
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
    );
  }

  _handleDragStarted(int index) {
    _initState();
    _initTransformState();
    _dragIndexNotifier.value = index;
    _dragWidgetSizeNotifier.value = _sizes[index];
    _targetIndex = index;
    _targetOffset = _offsets[index];
    _dragRect = Rect.fromLTWH(
      _targetOffset.dx + _parentOffset.dx,
      _targetOffset.dy + _parentOffset.dy,
      _sizes[index].width,
      _sizes[index].height,
    );
  }

  _handleDragEnd(DraggableDetails details) async {
    if (_targetIndex == -1) {
      return;
    }
    final children = List<GridItem>.from(_childrenNotifier.value);
    children.insert(_targetIndex, children.removeAt(_dragIndexNotifier.value));
    _childrenNotifier.value = children;
    _transformTweenMapNotifier.value = List.filled(
      length,
      Tween(
        begin: Offset.zero,
        end: Offset.zero,
      ),
    ).asMap();
    const spring = SpringDescription(
      mass: 1,
      stiffness: 100,
      damping: 10,
    );
    final simulation = SpringSimulation(spring, 0, 1, 0);
    _fakeDragWidgetAnimation = Tween(
      begin: details.offset - _parentOffset,
      end: _targetOffset,
    ).animate(_fakeDragWidgetController);
    _animating.value = true;
    await _fakeDragWidgetController.animateWith(simulation);
    _animating.value = false;
    _fakeDragWidgetAnimation = null;
    _initState();
  }

  _handleDragUpdate(DragUpdateDetails details) {
    _dragRect = _dragRect.translate(
      0,
      details.delta.dy,
    );
    _edgeDraggingAutoScroller?.startAutoScrollIfNecessary(_dragRect);
  }

  _handleWill(int index) async {
    final dragIndex = _dragIndexNotifier.value;
    if (dragIndex < 0 || dragIndex > _offsets.length - 1) {
      return;
    }
    final targetIndex = _tempIndexList.indexWhere((i) => i == index);
    if (_targetIndex == targetIndex) {
      return;
    }
    _tempIndexList = List.generate(length, (i) {
      if (i == targetIndex) return _dragIndexNotifier.value;
      if (_targetIndex > targetIndex && i > targetIndex && i <= _targetIndex) {
        return _tempIndexList[i - 1];
      } else if (_targetIndex < targetIndex &&
          i >= _targetIndex &&
          i < targetIndex) {
        return _tempIndexList[i + 1];
      }
      return _tempIndexList[i];
    }).toList();
    _targetIndex = targetIndex;
    final nextOffsets = _transform();
    _targetOffset = nextOffsets[_targetIndex];
  }

  List<Offset> _transform() {
    List<Offset> layoutOffsets = [
      Offset(_containerSize.width, 0),
    ];
    final List<Offset> nextOffsets = [];
    for (final index in _tempIndexList) {
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

    final Map<int, Tween<Offset>> transformTweenMap = {};

    for (final index in _tempIndexList) {
      final nextIndex = _tempIndexList.indexWhere((i) => i == index);
      transformTweenMap[index] = Tween(
        begin: _transformTweenMapNotifier.value[index]!.begin,
        end: nextOffsets[nextIndex] - _offsets[index],
      );
    }

    _transformTweenMapNotifier.value = transformTweenMap;

    // final List<Tween<Offset>> transformTweenList = [];
    // for (int index = 0; index < _offsets.length; index++) {
    //   final nextIndex = _tempIndexList.indexWhere((i) => i == index);
    //   if (nextIndex == -1) {
    //     continue;
    //   }
    //   transformTweenList.add(Tween(
    //     begin: _transformTweenListNotifier.value[index].begin,
    //     end: nextOffsets[nextIndex] - _offsets[index],
    //   ));
    // }
    //
    // _transformTweenListNotifier.value = transformTweenList;

    return nextOffsets;
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

  Widget _shakeWrap(Widget child) {
    final random = 0.7 + Random().nextDouble() * 0.3;
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        return Transform.rotate(
          angle: _animation.value * random,
          child: child!,
        );
      },
      child: child,
    );
  }

  _handleDelete(int index) {
    _initTransformState();
    final indexWhere = _tempIndexList.indexWhere((i) => i == index);
    _tempIndexList.removeAt(indexWhere);
    _transform();
    Future.delayed(commonDuration, () {
      _initState();
      final children = List<GridItem>.from(_childrenNotifier.value);
      children.removeAt(index);
      _childrenNotifier.value = children;
    });
  }

  Widget _draggableWrap({
    required Widget childWhenDragging,
    required Widget feedback,
    required Widget target,
    required int index,
  }) {
    return ValueListenableBuilder(
      valueListenable: isEditNotifier,
      builder: (_, isEdit, child) {
        if (!isEdit) {
          return target;
        }
        return _shakeWrap(
          _DeletableContainer(
            onDelete: () {
              _handleDelete(index);
            },
            child: child!,
          ),
        );
      },
      child: system.isDesktop
          ? Draggable(
              childWhenDragging: childWhenDragging,
              data: index,
              feedback: feedback,
              onDragStarted: () {
                _handleDragStarted(index);
              },
              onDragUpdate: (details) {
                _handleDragUpdate(details);
              },
              onDragEnd: (details) {
                _handleDragEnd(details);
              },
              child: target,
            )
          : LongPressDraggable(
              childWhenDragging: childWhenDragging,
              data: index,
              feedback: feedback,
              onDragStarted: () {
                _handleDragStarted(index);
              },
              onDragUpdate: (details) {
                _handleDragUpdate(details);
              },
              onDragEnd: (details) {
                _handleDragEnd(details);
              },
              child: target,
            ),
    );
  }

  Widget _builderItem(int index) {
    final girdItem = _childrenNotifier.value[index];
    final child = girdItem.child;
    return GridItem(
      mainAxisCellCount: girdItem.mainAxisCellCount,
      crossAxisCellCount: girdItem.crossAxisCellCount,
      child: Builder(
        builder: (context) {
          _itemContexts[index] = context;
          final childWhenDragging = IgnorePointer(
            ignoring: true,
            child: Opacity(
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
              return child;
            },
            onWillAcceptWithDetails: (_) {
              debouncer
                  .call(DebounceTag.handleWill, _handleWill, args: [index]);
              return false;
            },
          );

          return _wrapTransform(
            _draggableWrap(
              childWhenDragging: childWhenDragging,
              feedback: feedback,
              target: target,
              index: index,
            ),
            index,
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
              child: _childrenNotifier.value[index].child,
            ),
          ),
          index,
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _fakeDragWidgetController.dispose();
    _controller.dispose();
    _dragIndexNotifier.dispose();
    _dragIndexNotifier.dispose();
    _transformTweenMapNotifier.dispose();
    _animating.dispose();
    _childrenNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DeferredPointerHandler(
      child: Stack(
        children: [
          _ignoreWrap(
            ValueListenableBuilder(
              valueListenable: _childrenNotifier,
              builder: (_, children, __) {
                _tempIndexList = List.generate(length, (index) => index);
                _itemContexts = List.filled(
                  length,
                  null,
                );
                _transformTweenMapNotifier.value = List.filled(
                  length,
                  Tween(
                    begin: Offset.zero,
                    end: Offset.zero,
                  ),
                ).asMap();
                return Grid(
                  axisDirection: AxisDirection.down,
                  crossAxisCount: crossCount,
                  crossAxisSpacing: widget.crossAxisSpacing,
                  mainAxisSpacing: widget.mainAxisSpacing,
                  children: [
                    for (int i = 0; i < children.length; i++) _builderItem(i),
                  ],
                );
              },
            ),
          ),
          _buildFakeTransformWidget(),
        ],
      ),
    );
  }
}

class _DeletableContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _DeletableContainer({
    required this.child,
    required this.onDelete,
  });

  @override
  State<_DeletableContainer> createState() => _DeletableContainerState();
}

class _DeletableContainerState extends State<_DeletableContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _deleteButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: commonDuration,
    );
    _scaleAnimation = Tween(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    _fadeAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
  }

  _handleDel() async {
    setState(() {
      _deleteButtonVisible = false;
    });
    await _controller.forward(from: 0);
    widget.onDelete();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _controller.view,
          builder: (_, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child!,
              ),
            );
          },
          child: widget.child,
        ),
        if (_deleteButtonVisible)
          Positioned(
            top: -8,
            right: -8,
            child: DeferPointer(
              child: SizedBox(
                width: 24,
                height: 24,
                child: IconButton.filled(
                  iconSize: 20,
                  padding: EdgeInsets.all(2),
                  onPressed: _handleDel,
                  icon: Icon(
                    Icons.close,
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}
