import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/teleprompter_constants.dart';
import '../models/song.dart';
import '../widgets/reader_controls.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.song,
    required this.onSettingsChanged,
  });

  final Song song;
  final Future<void> Function(double speed, double fontSize)
      onSettingsChanged;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _playbackTimer;
  bool _isPlaying = false;
  bool _areControlsVisible = true;
  bool _isManualScrollActive = false;
  bool _shouldResumeAfterManualScroll = false;
  late double _speed;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _speed = widget.song.speed;
    _fontSize = widget.song.fontSize;
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() =>
      widget.onSettingsChanged(_speed, _fontSize);

  void _startPlayback() {
    setState(() => _isPlaying = true);
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      const Duration(
        milliseconds: TeleprompterConstants.playbackTickMilliseconds,
      ),
      (_) {
        if (!_scrollController.hasClients) return;

        final maxScrollOffset = _scrollController.position.maxScrollExtent;
        final nextScrollOffset = _scrollController.offset +
            _speed / TeleprompterConstants.pixelsPerSpeedUnitTick;
        if (nextScrollOffset >= maxScrollOffset) {
          _scrollController.jumpTo(maxScrollOffset);
          _playbackTimer?.cancel();
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _shouldResumeAfterManualScroll = false;
            });
          }
          return;
        }
        _scrollController.jumpTo(nextScrollOffset);
      },
    );
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    if (_isPlaying && mounted) setState(() => _isPlaying = false);
  }

  void _togglePlayback() {
    _shouldResumeAfterManualScroll = false;
    if (_isPlaying) {
      _pausePlayback();
      return;
    }
    _startPlayback();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _isManualScrollActive = true;
      _shouldResumeAfterManualScroll = _isPlaying;
      if (_isPlaying) _pausePlayback();
    } else if (notification is ScrollEndNotification &&
        _isManualScrollActive) {
      _isManualScrollActive = false;
      final shouldResume = _shouldResumeAfterManualScroll;
      _shouldResumeAfterManualScroll = false;
      if (shouldResume && mounted) _startPlayback();
    }
    return false;
  }

  void _restartPlayback() {
    _playbackTimer?.cancel();
    _shouldResumeAfterManualScroll = false;
    _isManualScrollActive = false;
    setState(() => _isPlaying = false);
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _setSpeed(double value) => setState(() => _speed = value);

  void _setFontSize(double value) => setState(() => _fontSize = value);

  void _saveCurrentSettings(double _) => unawaited(_saveSettings());

  void _showControls() => setState(() => _areControlsVisible = true);

  void _hideControls() => setState(() => _areControlsVisible = false);

  Widget _buildReader({required bool landscape}) =>
      NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            landscape ? 18 : 28,
            _areControlsVisible && !landscape ? 48 : 20,
            landscape ? 18 : 28,
            _areControlsVisible && !landscape ? 140 : 32,
          ),
          children: [
            Text(
              widget.song.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF2F3EE),
              ),
            ),
          ],
        ),
      );

  Widget _buildRestoreControlsButton() => Positioned(
        top: 4,
        right: 4,
        child: Material(
          color: const Color(0xCC1B201B),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Mostrar controles',
            onPressed: _showControls,
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final reader = _buildReader(landscape: isLandscape);
    final controls = ReaderControls(
      playing: _isPlaying,
      speed: _speed,
      fontSize: _fontSize,
      landscape: isLandscape,
      onTogglePlay: _togglePlayback,
      onSpeed: _setSpeed,
      onFontSize: _setFontSize,
      onSpeedEnd: _saveCurrentSettings,
      onFontSizeEnd: _saveCurrentSettings,
    );

    return Scaffold(
      appBar: _areControlsVisible
          ? AppBar(
              title: Text(
                widget.song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Volver al inicio',
                  onPressed: _restartPlayback,
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
                IconButton(
                  tooltip: 'Ocultar controles',
                  onPressed: _hideControls,
                  icon: const Icon(Icons.fullscreen_rounded),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: !_areControlsVisible
            ? Stack(
                fit: StackFit.expand,
                children: [reader, _buildRestoreControlsButton()],
              )
            : isLandscape
                ? Row(
                    children: [
                      Expanded(child: reader),
                      SizedBox(
                        width: TeleprompterConstants.landscapeControlsWidth,
                        child: controls,
                      ),
                    ],
                  )
                : Column(
                    children: [Expanded(child: reader), controls],
                  ),
      ),
    );
  }
}
