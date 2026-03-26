import 'package:flutter/material.dart';

class UrlChipList extends StatelessWidget {
  const UrlChipList({
    super.key,
    required this.urls,
    required this.onRemove,
    required this.onReorder,
  });

  final List<String> urls;
  final ValueChanged<int> onRemove;
  final ReorderCallback onReorder;

  String _displayUrl(String url) => url.replaceFirst(RegExp(r'^.*\.com/'), '');

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Scrollbar(
      thumbVisibility: true,
      child: ReorderableListView.builder(
        padding: EdgeInsets.zero,
        buildDefaultDragHandles: false,
        clipBehavior: Clip.hardEdge,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 0,
            color: Colors.transparent,
            child: child,
          );
        },
        itemCount: urls.length,
        onReorder: onReorder,
        itemBuilder: (context, i) => SizedBox(
          key: ValueKey('${urls[i]}-$i'),
          height: 54,
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.only(left: 12, right: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              _displayUrl(urls[i]),
                              maxLines: 1,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          icon: const Icon(Icons.close),
                          onPressed: () => onRemove(i),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: i,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
