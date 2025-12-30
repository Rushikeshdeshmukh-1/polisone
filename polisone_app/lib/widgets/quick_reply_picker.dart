import 'package:flutter/material.dart';

class QuickReplyPicker extends StatelessWidget {
  final Function(String) onReplySelected;

  const QuickReplyPicker({
    Key? key,
    required this.onReplySelected,
  }) : super(key: key);

  static const List<Map<String, dynamic>> quickReplies = [
    {'icon': Icons.check_circle, 'text': 'Acknowledged', 'color': Colors.green},
    {'icon': Icons.directions_run, 'text': 'On my way', 'color': Colors.blue},
    {'icon': Icons.done_all, 'text': 'Completed', 'color': Colors.green},
    {'icon': Icons.help_outline, 'text': 'Need backup', 'color': Colors.orange},
    {'icon': Icons.location_on, 'text': 'Arrived at location', 'color': Colors.blue},
    {'icon': Icons.warning, 'text': 'Situation under control', 'color': Colors.orange},
    {'icon': Icons.report_problem, 'text': 'Requesting assistance', 'color': Colors.red},
    {'icon': Icons.info, 'text': 'Will update shortly', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFF1E40AF)),
              const SizedBox(width: 8),
              const Text(
                'Quick Replies',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: quickReplies.length,
            itemBuilder: (context, index) {
              final reply = quickReplies[index];
              return InkWell(
                onTap: () {
                  onReplySelected(reply['text'] as String);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (reply['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (reply['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reply['icon'] as IconData,
                        color: reply['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reply['text'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: reply['color'] as Color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
