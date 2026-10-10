import '../core/constants/teleprompter_constants.dart';

class Song {
  static int _idCounter = 0;

  Song({
    String? id,
    required this.title,
    required this.text,
    this.speed = TeleprompterConstants.defaultSpeed,
    this.fontSize = TeleprompterConstants.defaultFontSize,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  final String id;
  final String title;
  final String text;
  final double speed;
  final double fontSize;

  Song copyWith({double? speed, double? fontSize}) => Song(
        id: id,
        title: title,
        text: text,
        speed: speed ?? this.speed,
        fontSize: fontSize ?? this.fontSize,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'speed': speed,
        'fontSize': fontSize,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String?,
        title: json['title'] as String,
        text: json['text'] as String,
        speed: (json['speed'] as num?)?.toDouble() ??
            TeleprompterConstants.defaultSpeed,
        fontSize: (json['fontSize'] as num?)?.toDouble() ??
            TeleprompterConstants.defaultFontSize,
      );
}
