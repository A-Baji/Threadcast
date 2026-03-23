class TranscriptFile {
  final List<TranscriptSpeaker> speakers;
  final List<PlayableSegment> segments;

  TranscriptFile({required this.speakers, required this.segments});

  factory TranscriptFile.fromJson(Map<String, dynamic> json) {
    return TranscriptFile(
      speakers: (json['speakers'] as List<dynamic>? ?? const [])
          .map((s) => TranscriptSpeaker.fromJson(s as Map<String, dynamic>))
          .toList(),
      segments: (json['segments'] as List<dynamic>? ?? const [])
          .map((s) => PlayableSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TranscriptSpeaker {
  final String id;
  final String? redditUsername;
  final String role;

  TranscriptSpeaker({required this.id, this.redditUsername, required this.role});

  factory TranscriptSpeaker.fromJson(Map<String, dynamic> json) => TranscriptSpeaker(
        id: json['id'] as String,
        redditUsername: json['reddit_username'] as String?,
        role: json['role'] as String,
      );
}

class PlayableSegment {
  final String speakerId;
  final String text;
  final Duration audioOffset;
  final Duration audioDuration;

  PlayableSegment({
    required this.speakerId,
    required this.text,
    required this.audioOffset,
    required this.audioDuration,
  });

  factory PlayableSegment.fromJson(Map<String, dynamic> json) => PlayableSegment(
        speakerId: json['speaker_id'] as String,
        text: json['text'] as String,
        audioOffset: Duration(milliseconds: (json['audio_offset_ms'] as int?) ?? 0),
        audioDuration: Duration(milliseconds: (json['audio_duration_ms'] as int?) ?? 0),
      );
}
