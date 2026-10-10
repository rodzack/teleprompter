import 'package:flutter/material.dart';

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({
    super.key,
    required this.hasSongs,
    required this.onImport,
    required this.onAddSong,
  });

  final bool hasSongs;
  final VoidCallback onImport;
  final VoidCallback onAddSong;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            hasSongs ? Icons.search_off_rounded : Icons.queue_music_rounded,
            size: 54,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            hasSongs ? 'No encontramos coincidencias' : 'Tu repertorio empieza aquí',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            hasSongs
                ? 'Prueba con otro título o fragmento.'
                : 'Importa varias canciones a la vez.',
            style: const TextStyle(color: Colors.white60),
          ),
          if (!hasSongs) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar canciones'),
            ),
            TextButton.icon(
              onPressed: onAddSong,
              icon: const Icon(Icons.edit_note),
              label: const Text('Añadir canción'),
            ),
          ],
        ]),
      );
}
