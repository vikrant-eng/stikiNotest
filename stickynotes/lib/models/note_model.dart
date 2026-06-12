// lib/models/note_model.dart

class Note {
  final int? id;
  final String title;
  final String content;
  final int color;
  final String createdAt;
  final bool isProtected;
  final String? pinCode;
  final bool useBiometric;

  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    this.isProtected = false,
    this.pinCode,
    this.useBiometric = false,
  });

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? color,
    String? createdAt,
    bool? isProtected,
    String? pinCode,
    bool? useBiometric,
    bool clearPin = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      isProtected: isProtected ?? this.isProtected,
      pinCode: clearPin ? null : (pinCode ?? this.pinCode),
      useBiometric: useBiometric ?? this.useBiometric,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'color': color,
      'createdAt': createdAt,
      'isProtected': isProtected ? 1 : 0,
      'pinCode': pinCode,
      'useBiometric': useBiometric ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      color: map['color'] as int? ?? 0xFFFFF9C4,
      createdAt: map['createdAt'] as String? ?? '',
      isProtected: (map['isProtected'] as int? ?? 0) == 1,
      pinCode: map['pinCode'] as String?,
      useBiometric: (map['useBiometric'] as int? ?? 0) == 1,
    );
  }
}