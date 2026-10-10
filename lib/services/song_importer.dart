import 'dart:convert';
import 'dart:typed_data';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/teleprompter_constants.dart';
import '../models/song.dart';

class SongImportResult {
  const SongImportResult({required this.songs, required this.skippedCount});

  final List<Song> songs;
  final int skippedCount;
}

class SongImporter {
  Future<SongImportResult> importSongs() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: TeleprompterConstants.songFileExtensions,
    );
    if (files.isEmpty) {
      return const SongImportResult(songs: [], skippedCount: 0);
    }

    final songs = <Song>[];
    var skippedCount = 0;
    for (final file in files) {
      final song = await _readSong(file);
      if (song == null) {
        skippedCount++;
      } else {
        songs.add(song);
      }
    }
    return SongImportResult(songs: songs, skippedCount: skippedCount);
  }

  Future<Song?> _readSong(PlatformFile file) async {
    final extension = (file.extension ?? '').toLowerCase();
    if (extension == 'doc') return null;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      debugPrint('No se pudo leer el archivo ${file.name}: $error');
      return null;
    }

    final text = extension == 'docx'
        ? docxToText(bytes)
        : utf8.decode(bytes, allowMalformed: true);
    if (text.trim().isEmpty) return null;

    final title = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '').trim();
    return Song(title: title.isEmpty ? 'Canción' : title, text: text.trim());
  }
}
