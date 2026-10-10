import 'package:flutter/material.dart';

import '../core/constants/teleprompter_constants.dart';

class ReaderControls extends StatelessWidget {
  const ReaderControls({
    super.key,
    required this.playing,
    required this.speed,
    required this.fontSize,
    required this.landscape,
    required this.onTogglePlay,
    required this.onSpeed,
    required this.onFontSize,
    required this.onSpeedEnd,
    required this.onFontSizeEnd,
  });

  final bool playing;
  final double speed;
  final double fontSize;
  final bool landscape;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSpeed;
  final ValueChanged<double> onFontSize;
  final ValueChanged<double> onSpeedEnd;
  final ValueChanged<double> onFontSizeEnd;

  @override
  Widget build(BuildContext context) {
    if (landscape) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFF1B201B),
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LandscapeSlider(
                label: 'Velocidad',
                value: speed,
                min: TeleprompterConstants.minimumSpeed,
                max: TeleprompterConstants.maximumSpeed,
                divisions: TeleprompterConstants.speedDivisions,
                onChanged: onSpeed,
                onChangeEnd: onSpeedEnd,
              ),
              const SizedBox(height: 12),
              _LandscapeSlider(
                label: 'Tamaño',
                value: fontSize,
                min: TeleprompterConstants.minimumFontSize,
                max: TeleprompterConstants.maximumFontSize,
                divisions: TeleprompterConstants.fontSizeDivisions,
                suffix: ' px',
                onChanged: onFontSize,
                onChangeEnd: onFontSizeEnd,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onTogglePlay,
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(playing ? 'Pausar' : 'Iniciar'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desliza para mover la letra',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1B201B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.slow_motion_video, size: 20),
              const SizedBox(width: 7),
              const Text('Velocidad'),
              Expanded(
                child: Slider(
                  min: TeleprompterConstants.minimumSpeed,
                  max: TeleprompterConstants.maximumSpeed,
                  divisions: TeleprompterConstants.speedDivisions,
                  value: speed,
                  onChanged: onSpeed,
                  onChangeEnd: onSpeedEnd,
                ),
              ),
              SizedBox(
                width: 44,
                child: Text('${speed.round()}', textAlign: TextAlign.end),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.text_fields, size: 20),
              const SizedBox(width: 7),
              const Text('Tamaño'),
              Expanded(
                child: Slider(
                  min: TeleprompterConstants.minimumFontSize,
                  max: TeleprompterConstants.maximumFontSize,
                  divisions: TeleprompterConstants.fontSizeDivisions,
                  value: fontSize,
                  onChanged: onFontSize,
                  onChangeEnd: onFontSizeEnd,
                ),
              ),
              SizedBox(
                width: 44,
                child: Text('${fontSize.round()} px', textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe_vertical_rounded,
                  size: 18, color: Colors.white60),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Desliza hacia arriba o abajo para ajustar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white60),
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: onTogglePlay,
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(playing ? 'Pausar' : 'Iniciar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandscapeSlider extends StatelessWidget {
  const _LandscapeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
    this.suffix = '',
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${value.round()}$suffix',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      );
}
