class Transcript {
  final String episodeId;
  final String episodeTitle;
  final String tone;
  final List<Speaker> speakers;
  final List<TranscriptSegment> segments;

  Transcript({
    required this.episodeId,
    required this.episodeTitle,
    required this.tone,
    required this.speakers,
    required this.segments,
  });
}

class Speaker {
  final String id; // "op", "speaker_2", etc.
  final String? redditUsername;
  final String role; // "main_speaker" | "commenter"
  final String personalityNotes;
  final String voiceGender; // "male" | "female"
  final String assignedVoice; // Set during voice assignment (Kokoro voice name)

  Speaker({
    required this.id,
    this.redditUsername,
    required this.role,
    required this.personalityNotes,
    required this.voiceGender,
    required this.assignedVoice,
  });

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'],
      redditUsername: json['reddit_username'],
      role: json['role'],
      personalityNotes: json['personality_notes'],
      voiceGender: json['voice_gender'],
      assignedVoice: '', // Set later
    );
  }
}

class TranscriptSegment {
  final String speakerId;
  final String text;
  final DeliveryInstructions delivery;
  // Set after TTS synthesis:
  final String? audioFilePath;
  final Duration? audioDuration;
  final Duration? audioOffset; // Start time within final stitched audio

  TranscriptSegment({
    required this.speakerId,
    required this.text,
    required this.delivery,
    this.audioFilePath,
    this.audioDuration,
    this.audioOffset,
  });

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      speakerId: json['speaker_id'],
      text: json['text'],
      delivery: DeliveryInstructions.fromJson(json['delivery']),
    );
  }

  TranscriptSegment copyWith({
    String? audioFilePath,
    Duration? audioDuration,
    Duration? audioOffset,
  }) {
    return TranscriptSegment(
      speakerId: speakerId,
      text: text,
      delivery: delivery,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      audioDuration: audioDuration ?? this.audioDuration,
      audioOffset: audioOffset ?? this.audioOffset,
    );
  }
}

class DeliveryInstructions {
  final String pace; // "normal" | "slow" | "fast"
  final String emotion;
  final int pauseBeforeMs;
  final bool overlapPrevious;

  DeliveryInstructions({
    required this.pace,
    required this.emotion,
    required this.pauseBeforeMs,
    required this.overlapPrevious,
  });

  factory DeliveryInstructions.fromJson(Map<String, dynamic> json) {
    return DeliveryInstructions(
      pace: json['pace'],
      emotion: json['emotion'],
      pauseBeforeMs: json['pause_before_ms'],
      overlapPrevious: json['overlap_previous'],
    );
  }
}
