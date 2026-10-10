import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song_importer.dart';
import '../services/song_repository.dart';
import '../widgets/empty_library.dart';
import '../widgets/song_tile.dart';
import 'reader_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final SongRepository _songRepository = SongRepository();
  final SongImporter _songImporter = SongImporter();

  List<Song> _songs = [];
  bool _isLoading = true;
  bool _isImporting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _songRepository.loadSongs();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('No se pudo cargar la biblioteca de canciones: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('No se pudo cargar la biblioteca. Inténtalo de nuevo.');
    }
  }

  Future<void> _saveSongs() async {
    try {
      await _songRepository.saveSongs(_songs);
    } catch (error) {
      debugPrint('No se pudo guardar la biblioteca de canciones: $error');
      _showMessage('No se pudieron guardar los cambios. Inténtalo de nuevo.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _importSongs() async {
    setState(() => _isImporting = true);
    try {
      final result = await _songImporter.importSongs();
      if (!mounted) return;

      if (result.songs.isNotEmpty) {
        setState(() => _songs = [..._songs, ...result.songs]);
        await _saveSongs();
      }

      if (result.skippedCount > 0) {
        _showMessage(
          '${result.songs.length} canciones añadidas. '
          '${result.skippedCount} archivo(s) omitidos; convierte los .doc a .docx.',
        );
      } else if (result.songs.isNotEmpty) {
        _showMessage('${result.songs.length} canciones añadidas a tu biblioteca.');
      }
    } catch (error) {
      debugPrint('No se pudieron importar las canciones: $error');
      _showMessage('No se pudieron importar los archivos. Revisa su formato e inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _addSongManually() async {
    final titleController = TextEditingController();
    final lyricsController = TextEditingController();

    try {
      final song = await showDialog<Song>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Añadir canción'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lyricsController,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(labelText: 'Letra'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final lyrics = lyricsController.text.trim();
                if (title.isEmpty || lyrics.isEmpty) return;
                Navigator.pop(
                  context,
                  Song(title: title, text: lyrics),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (song == null || !mounted) return;
      setState(() => _songs = [..._songs, song]);
      await _saveSongs();
    } finally {
      titleController.dispose();
      lyricsController.dispose();
    }
  }

  Future<void> _deleteSong(Song song) async {
    setState(() => _songs = _songs.where((item) => item.id != song.id).toList());
    await _saveSongs();
  }

  Future<void> _updateSongSettings(
      String songId, double speed, double fontSize) async {
    final songIndex = _songs.indexWhere((song) => song.id == songId);
    if (songIndex < 0) return;

    setState(() {
      _songs[songIndex] =
          _songs[songIndex].copyWith(speed: speed, fontSize: fontSize);
    });
    await _saveSongs();
  }

  void _openSong(Song song) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderPage(
          song: song,
          onSettingsChanged: (speed, fontSize) =>
              _updateSongSettings(song.id, speed, fontSize),
        ),
      ),
    );
  }

  List<Song> _getVisibleSongs() {
    final query = _searchQuery.toLowerCase();
    return _songs
        .where((song) =>
            song.title.toLowerCase().contains(query) ||
            song.text.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildSearchField() => TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Buscar canción o letra',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFF1B201B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      );

  Widget _buildLibraryHeader(BuildContext context, bool landscape) {
    final songCountLabel =
        '${_songs.length} ${_songs.length == 1 ? 'canción' : 'canciones'}';
    final libraryLabel = Text(
      'TU REPERTORIO',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFFB7F36B),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
    final songCount = Text(
      songCountLabel,
      style: (landscape
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.headlineSmall)
          ?.copyWith(fontWeight: FontWeight.w700),
    );

    if (landscape) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [libraryLabel, const SizedBox(height: 5), songCount],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildSearchField()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        libraryLabel,
        const SizedBox(height: 5),
        songCount,
        const SizedBox(height: 18),
        _buildSearchField(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final visibleSongs = _getVisibleSongs();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.graphic_eq_rounded, color: Color(0xFFB7F36B)),
            SizedBox(width: 10),
            Text('Teleprompter', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: _songs.isEmpty
            ? null
            : [
                IconButton(
                  tooltip: 'Importar canciones',
                  onPressed: _isImporting ? null : _importSongs,
                  icon: _isImporting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_upload_outlined),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLibraryHeader(context, landscape),
              const SizedBox(height: 12),
              if (_songs.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addSongManually,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Añadir canción'),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : visibleSongs.isEmpty
                        ? EmptyLibrary(
                            hasSongs: _songs.isNotEmpty,
                            onImport: _importSongs,
                            onAddSong: _addSongManually,
                          )
                        : ListView.separated(
                            itemCount: visibleSongs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final song = visibleSongs[index];
                              return SongTile(
                                song: song,
                                onTap: () => _openSong(song),
                                onDelete: () => _deleteSong(song),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
