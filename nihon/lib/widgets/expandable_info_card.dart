import 'package:flutter/material.dart';

class ExpandableInfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color iconColor;
  final double contentFontSize;

  const ExpandableInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.iconColor,
    this.contentFontSize = 18,
  });

  @override
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard> {
  bool isExpanded = false;

  static const Color borderColor = Color(0xFFE8DCCB);
  static const Color textDark = Color(0xFF2D261F);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: borderColor),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              widget.icon,
              color: widget.iconColor,
            ),
            title: Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.content,
                  style: TextStyle(
                    fontSize: widget.contentFontSize,
                    height: 1.5,
                    color: textDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}