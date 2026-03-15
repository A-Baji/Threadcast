import '../llm/models/transcript.dart';

class VoiceAssignment {
  // Kokoro built-in voices
  static const _maleVoices = ['am_adam', 'am_michael', 'am_fenrir'];
  static const _femaleVoices = ['af_sarah', 'af_bella', 'af_nicole'];
  static const _neutralVoices = ['am_adam', 'af_sarah']; // Fallback

  static final _roleVoices = {
    'main_speaker_male': 'am_adam',
    'main_speaker_female': 'af_sarah',
    'main_speaker_neutral': 'am_adam',
  };

  static Map<String, String> assignVoices(List<Speaker> speakers) {
    final assignment = <String, String>{};
    final usedVoices = <String>{};

    for (final speaker in speakers) {
      if (speaker.role == 'main_speaker') {
        final voice = _roleVoices['main_speaker_${speaker.voiceGender}']!;
        assignment[speaker.id] = voice;
        usedVoices.add(voice);
      }
    }

    // Assign distinct voices to commenters
    final commenters = speakers.where((s) => s.role == 'commenter').toList();
    for (final speaker in commenters) {
      final pool = speaker.voiceGender == 'female'
          ? _femaleVoices
          : speaker.voiceGender == 'male'
              ? _maleVoices
              : _neutralVoices;

      final available = pool.where((v) => !usedVoices.contains(v)).toList();
      final voice = available.isNotEmpty ? available.first : pool.first;
      assignment[speaker.id] = voice;
      usedVoices.add(voice);
    }

    return assignment;
  }
}