import 'package:flutter/material.dart';

import '../models/song.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onDelete,
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF1B201B),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFB7F36B).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.music_note_rounded, color: Color(0xFFB7F36B)),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            song.text.replaceAll('\n', ' '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (sheetContext) => SafeArea(
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Eliminar canción'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onDelete();
                  },
                ),
              ),
            ),
          ),
          onTap: onTap,
        ),
      );
}
