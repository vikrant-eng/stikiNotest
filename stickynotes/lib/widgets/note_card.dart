// lib/widgets/note_card.dart

import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(note.color);
    // Determine luminance to pick contrasting text colour
    final luminance = cardColor.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black87 : Colors.white;
    final subTextColor = luminance > 0.5
        ? Colors.black54
        : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          color: cardColor,
          elevation: 3,
          shadowColor: cardColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white24,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isProtected)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: textColor.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── Content preview ──────────────────────────────────────
                  if (!note.isProtected && note.content.isNotEmpty) ...[
                    Text(
                      note.content,
                      style:
                          TextStyle(fontSize: 13, color: subTextColor),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ] else if (note.isProtected) ...[
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 13, color: subTextColor),
                        const SizedBox(width: 4),
                        Text(
                          'Protected content',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: subTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // ── Footer row ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(note.createdAt),
                        style: TextStyle(
                            fontSize: 10, color: subTextColor),
                      ),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}