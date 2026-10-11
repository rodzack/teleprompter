import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

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
        ? _extractDocxText(bytes)
        : utf8.decode(bytes, allowMalformed: true);
    if (text.trim().isEmpty) return null;

    final title = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '').trim();
    return Song(title: title.isEmpty ? 'Canción' : title, text: text.trim());
  }

  String _extractDocxText(Uint8List bytes) {
    final documentFile =
        ZipDecoder().decodeBytes(bytes).findFile('word/document.xml');
    if (documentFile == null) {
      throw const FormatException('El documento no contiene texto principal.');
    }

    final document = XmlDocument.parse(utf8.decode(documentFile.content));
    final paragraphs = document.findAllElements('w:p');
    return paragraphs.map(_extractParagraphText).join('\n');
  }

  String _extractParagraphText(XmlElement paragraph) =>
      paragraph.nodes.map(_extractTextNode).join();

  String _extractTextNode(XmlNode node) {
    if (node is! XmlElement) return '';

    switch (node.name.local) {
      case 't':
        return node.innerText;
      case 'br':
      case 'cr':
        return '\n';
      case 'tab':
        return '\t';
      default:
        return node.nodes.map(_extractTextNode).join();
    }
  }
}
