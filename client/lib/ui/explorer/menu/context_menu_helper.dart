import 'dart:math';

import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:phylum/ui/explorer/menu/option_groups.dart';

final _controller = ContextMenuController();

sealed class ContextMenuHelper {
  ContextMenuHelper._();

  static void show({
    required BuildContext context,
    required Offset position,
    required MenuOptionGroups groups,
    required void Function(MenuOption option) onOptionSelected,
  }) {
    final items = groups
        .map(
          (group) => group.map(
            (option) => InkWell(
              onTap: () {
                _controller.remove();
                onOptionSelected(option);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(option.icon, size: 18.0),
                    Text(option.text, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        )
        .fold<Iterable<Widget>>([], (acc, e) {
          if (e.isEmpty) {
            return acc;
          }
          if (acc.isEmpty) {
            return e.toList(growable: false);
          }
          return [...acc, const Divider(height: 12.0), ...e];
        })
        .toList(growable: false);
    final list = ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      physics: ClampingScrollPhysics(),
      children: items,
    );
    _controller.show(
      context: context,
      contextMenuBuilder: (context) {
        return PositionedContextMenu(position: position, child: list);
      },
    );
  }

  static bool remove() {
    if (_controller.isShown) {
      _controller.remove();
      return true;
    }
    return false;
  }
}

class PositionedContextMenu extends StatefulWidget {
  final Widget child;
  final Offset position;

  const PositionedContextMenu({required this.child, required this.position});

  @override
  State<PositionedContextMenu> createState() => _PositionedContextMenuState();
}

class _PositionedContextMenuState extends State<PositionedContextMenu> {
  final GlobalKey _offstageKey = GlobalKey();
  double height = 0.0;
  bool _offstage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _offstageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() {
          _offstage = false;
          height = renderBox.size.height;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const width = 300.0;

    final height = min(this.height, size.height / 2);
    final left = widget.position.dx + width > size.width
        ? null
        : widget.position.dx;
    final right = widget.position.dx + width > size.width
        ? size.width - widget.position.dx
        : null;

    final top = widget.position.dy + height > size.height
        ? null
        : widget.position.dy;

    final bottom = widget.position.dy + height > size.height
        ? size.height - widget.position.dy
        : null;

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width,
          maxWidth: width,
          maxHeight: height == 0.0 ? double.infinity : height,
        ),
        child: TapRegion(
          onTapOutside: (event) => _controller.remove(),
          child: Offstage(
            offstage: _offstage,
            child: Material(
              key: _offstageKey,
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
