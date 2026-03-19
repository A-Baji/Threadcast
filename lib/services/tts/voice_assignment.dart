import '../llm/models/transcript.dart';

class VoiceAssignment {
  // Kokoro built-in voices
  static const _maleVoices = ['am_fenrir', 'am_michael', 'am_puck'];
  static const _femaleVoices = ['af_bella', 'af_heart', 'af_nicole'];

  static final _roleVoices = {
    'main_speaker_male': 'am_fenrir', // C+ — best available male
    'main_speaker_female': 'af_bella', // A- — best available female
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
      final pool = speaker.voiceGender == 'female' ? _femaleVoices : _maleVoices;

      final available = pool.where((v) => !usedVoices.contains(v)).toList();
      final voice = available.isNotEmpty ? available.first : pool.first;
      assignment[speaker.id] = voice;
      usedVoices.add(voice);
    }

    return assignment;
  }
}
