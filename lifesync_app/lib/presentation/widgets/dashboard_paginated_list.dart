import 'package:flutter/material.dart';
import 'package:lifesync_app/presentation/widgets/ls_design.dart';

class DashboardPaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final String title;
  final String hintText;
  final String emptyMessage;
  final Widget Function(T item) itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String Function(T item) idGetter;

  const DashboardPaginatedList({
    super.key,
    required this.items,
    required this.title,
    required this.hintText,
    required this.emptyMessage,
    required this.itemBuilder,
    required this.onReorder,
    required this.idGetter,
  });

  @override
  State<DashboardPaginatedList<T>> createState() => _DashboardPaginatedListState<T>();
}

class _DashboardPaginatedListState<T> extends State<DashboardPaginatedList<T>> {
  int _limit = 3;
  int _page = 0;

  @override
  void didUpdateWidget(covariant DashboardPaginatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure page is valid after items change
    final maxPage = _limit == -1 ? 0 : (widget.items.length - 1) ~/ _limit;
    if (_page > maxPage && maxPage >= 0) {
      _page = maxPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<T> displayItems;
    if (_limit == -1) {
      displayItems = widget.items;
    } else {
      final startIndex = _page * _limit;
      final endIndex = (startIndex + _limit).clamp(0, widget.items.length);
      displayItems = startIndex < widget.items.length ? widget.items.sublist(startIndex, endIndex) : [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: LsSectionHeader(title: widget.title)),
            Row(
              children: [
                _buildLimitButton(3, '3'),
                _buildLimitButton(5, '5'),
                _buildLimitButton(-1, 'Semua'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.drag_indicator, size: 12, color: LsColors.mute(context)),
            const SizedBox(width: 4),
            Expanded(child: Text(widget.hintText, style: TextStyle(fontSize: 11, color: LsColors.mute(context)))),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: LsColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LsColors.line(context)),
            ),
            child: Center(
              child: Text(widget.emptyMessage, style: TextStyle(color: LsColors.mute(context))),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              int actualOld = _limit == -1 ? oldIndex : (_page * _limit) + oldIndex;
              int actualNew = _limit == -1 ? newIndex : (_page * _limit) + newIndex;
              widget.onReorder(actualOld, actualNew);
            },
            itemBuilder: (context, index) {
              final item = displayItems[index];
              return Container(
                key: ValueKey(widget.idGetter(item)),
                margin: const EdgeInsets.only(bottom: 12.0),
                child: widget.itemBuilder(item),
              );
            },
          ),
        if (_limit != -1 && widget.items.length > _limit) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate((widget.items.length / _limit).ceil(), (index) {
              final isActive = index == _page;
              return GestureDetector(
                onTap: () => setState(() => _page = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? LsColors.brand : LsColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isActive ? LsColors.brand : LsColors.line(context)),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : LsColors.mute(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildLimitButton(int value, String label) {
    final isActive = _limit == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _limit = value;
          _page = 0;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? LsColors.brand.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? LsColors.brand : LsColors.line(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? LsColors.brand : LsColors.mute(context),
          ),
        ),
      ),
    );
  }
}
