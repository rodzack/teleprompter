import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

class SongRepository {
  static const _storageKey = 'teleprompter_songs_v1';

  Future<List<Song>> loadSongs() async {
    final preferences = await SharedPreferences.getInstance();
    final savedSongs = preferences.getString(_storageKey);
    if (savedSongs == null) return [];

    final decodedSongs = jsonDecode(savedSongs) as List<dynamic>;
    return decodedSongs
        .map((song) => Song.fromJson(song as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSongs(List<Song> songs) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedSongs = jsonEncode(songs.map((song) => song.toJson()).toList());
    await preferences.setString(_storageKey, encodedSongs);
  }
}
