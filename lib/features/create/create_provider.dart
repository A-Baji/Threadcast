import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/providers.dart';
import '../../models/episode.dart';
import '../../services/llm/models/transcript.dart';
import '../../services/tts/voice_assignment.dart';

final createProvider = StateNotifierProvider<CreateNotifier, CreateState>(
  (ref) => CreateNotifier(ref),
);

class CreateNotifier extends StateNotifier<CreateState> {
  final Ref _ref;

  CreateNotifier(this._ref) : super(const CreateState.idle());

  Future<void> checkCompatibilityOnLoad() async {
    if (state.hasCheckedCompatibility || state.status == CreateStatus.checkingCompatibility) {
      return;
    }

    state = state.copyWith(status: CreateStatus.checkingCompatibility, hasCheckedCompatibility: true, error: null);

    final supported = await _isOsVersionSupported();
    if (!supported) {
      state = state.copyWith(status: CreateStatus.unsupported);
      return;
    }

    state = state.copyWith(status: CreateStatus.idle);
  }

  Future<bool> _isOsVersionSupported() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt >= 36;
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final majorVersion = int.tryParse(iosInfo.systemVersion.split('.').first);
        return (majorVersion ?? 0) >= 18;
      }

      return true;
    } catch (_) {
      return true; // Default to supported on error
    }
  }

  void addUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.contains('reddit')) {
      return;
    }

    if (state.urls.contains(trimmed)) {
      return;
    }

    state = state.copyWith(urls: [...state.urls, trimmed]);
  }

  void removeUrl(int index) {
    if (index < 0 || index >= state.urls.length) {
      return;
    }

    final updated = [...state.urls]..removeAt(index);
    state = state.copyWith(urls: updated);
  }

  void reorderUrls(int oldIndex, int newIndex) {
    final updated = [...state.urls];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex < 0 || oldIndex >= updated.length || newIndex < 0 || newIndex >= updated.length) {
      return;
    }

    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(urls: updated);
  }

  Future<void> generatePodcast() async {
    final urls = List<String>.from(state.urls);
    if (urls.isEmpty || state.status == CreateStatus.unsupported) {
      return;
    }

    final episodeId = const Uuid().v4();

    try {
      await WakelockPlus.enable();
      state = state.copyWith(status: CreateStatus.scraping, error: null);
      final llm = _ref.read(llmServiceProvider);
      // if (!await llm.isAvailable()) {
      //   state = state.copyWith(
      //     status: CreateStatus.failed,
      //     error: 'On-device model is unavailable. Please verify your model setup and try again.',
      //   );
      //   return;
      // }

      final scraper = _ref.read(redditScraperProvider);
      final posts = await Future.wait(urls.map(scraper.fetchPost));

      // state = state.copyWith(status: CreateStatus.analyzing);
      // final promptBuilder = _ref.read(llmPromptBuilderProvider);
      // final analysisRaw = await llm.generateRaw(promptBuilder.buildAnalysisPrompt(posts));
      // final analysis = jsonDecode(analysisRaw) as Map<String, dynamic>;

      // state = state.copyWith(status: CreateStatus.generatingTranscript);
      // final transcriptRaw =
      //     await llm.generateRaw(promptBuilder.buildTranscriptPrompt(posts: posts, analysis: analysis));
      // final segments = (jsonDecode(transcriptRaw) as List)
      //     .map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>))
      //     .toList();
      final analysis = {
        "tone": "talk_show",
        "tone_reasoning":
            "The post follows a classic 'he-said-she-said' domestic dispute format that is ideal for a panel-style discussion. The conflict between a well-meaning parent and a passionate teenager, combined with the practical 'reality check' style of the comments, mirrors the dynamic of modern advice or call-in talk shows.",
        "speakers": [
          {
            "id": "op",
            "reddit_username": "frustratingbaconeate",
            "role": "main_speaker",
            "personality_notes":
                "Conversational and self-deprecating (calls himself an 'old fart'). He uses colloquialisms like 'team hell no' and 'kiddo,' and despite the conflict, his tone remains affectionate toward his daughter. He speaks with the cadence of a practical Midwesterner who values compromise but has a clear breaking point.",
            "voice_gender": "male"
          },
          {
            "id": "speaker_2",
            "reddit_username": "composite",
            "role": "commenter",
            "personality_notes":
                "Pragmatic, slightly ironic, and focused on logical workarounds. This speaker uses 'scare quotes' for words like 'tainted' to subtly point out the hyperbole of the teenager's demands. They suggest 'malicious compliance' solutions in a helpful, calm manner.",
            "voice_gender": "female",
            "merged_usernames": ["DoffyTrash", "ashe_the_cat", "InterminableSnowman"]
          },
          {
            "id": "speaker_3",
            "reddit_username": "DisenchantedMandrake",
            "role": "commenter",
            "personality_notes":
                "Blunt and assertive. They have no patience for teenage drama, using stronger descriptors like 'brat' and focusing on the financial reality of the situation (who pays the bills). They speak in short, punchy sentences that emphasize a 'tough love' perspective.",
            "voice_gender": "female",
            "merged_usernames": []
          }
        ],
        "selected_comment_ids": ["f4iwrlx", "f4j3xur", "f4j96ee", "f4jiabp"],
        "episode_title": "Sizzling Tensions: When Veganism Meets the Family Skillet"
      };
      final segments = [
        {
          "speaker_id": "op",
          "text":
              "Alright, so, look—I'll be the first to admit it. I'm an old fart. I've got a teenage daughter who I love to absolute pieces, but man, I am struggling to see eye to eye with her and my wife on this one. We're out here in the rural Midwest, right? Meat is just… it's what we do. Bacon for breakfast isn't just a preference; it's pretty much a given. It's the law of the land.",
          "delivery": {"pace": "normal", "emotion": "calm", "pause_before_ms": 0, "overlap_previous": false}
        },
        {
          "speaker_id": "op",
          "text":
              "But then, earlier this year, my fourteen-year-old decided she was going vegan. And honestly? I was all for it. I jumped onto her support team with real enthusiasm. I wasn't the dad rolling my eyes. We learned how to substitute ingredients together, we cooked new things, we tried the weirdest stuff you can imagine. I even adjusted our whole family budget to handle those—let's be honest—pretty expensive vegan substitutes for her. I wanted her to feel supported, you know?",
          "delivery": {"pace": "normal", "emotion": "excited", "pause_before_ms": 500, "overlap_previous": false}
        },
        {
          "speaker_id": "op",
          "text":
              "None of this was a problem. Not a lick of it. Until recently. I was in the kitchen, just doing my thing, cooking up some bacon in a pan. Standard morning. When I was done, I gave it a quick rinse in the sink and went to load it into the dishwasher. And that's when it happened. She just… exploded. Just total anger. Now, she's a teenager, so I'm not too fussed about the explosion itself—I know she doesn't really mean it—but she shouts at me that that was HER pan. Her special pan for vegan food.",
          "delivery": {"pace": "normal", "emotion": "frustrated", "pause_before_ms": 800, "overlap_previous": false}
        },
        {
          "speaker_id": "speaker_3",
          "text":
              "Wait, her pan? Is she the one paying the mortgage or the grocery bill? Because last I checked, that's not how a household works.",
          "delivery": {"pace": "fast", "emotion": "sarcastic", "pause_before_ms": 0, "overlap_previous": true}
        },
        {
          "speaker_id": "op",
          "text":
              "Exactly! I was completely floored. I told her, ‘Kiddo, this here is a family pan. This pan is literally older than you are. It's not YOUR pan.' But, look, I didn't want her to feel weird about her food. I didn't want it to be a whole thing. So I caved. I said sure. I went online and ordered her a few colored pans that are strictly for her vegan cooking. The colors are great because they help a guy like me remember, ‘Hey, don't touch these unless you're making her food.' Easy, right?",
          "delivery": {"pace": "normal", "emotion": "calm", "pause_before_ms": 400, "overlap_previous": false}
        },
        {
          "speaker_id": "speaker_2",
          "text":
              "You'd think so. But let me guess—the special colored pans didn't exactly solve the 'crisis' in the kitchen, did they?",
          "delivery": {"pace": "normal", "emotion": "sarcastic", "pause_before_ms": 200, "overlap_previous": false}
        },
        {
          "speaker_id": "speaker_3",
          "text": "TEST",
          "delivery": {"pace": "fast", "emotion": "sarcastic", "pause_before_ms": 1000, "overlap_previous": false}
        },
        {
          "speaker_id": "speaker_3",
          "text": "TEST",
          "delivery": {"pace": "normal", "emotion": "sarcastic", "pause_before_ms": 2000, "overlap_previous": false}
        },
        {
          "speaker_id": "speaker_3",
          "text": "TEST",
          "delivery": {"pace": "slow", "emotion": "sarcastic", "pause_before_ms": 3000, "overlap_previous": false}
        },
        // {
        //   "speaker_id": "op",
        //   "text":
        //       "Not even close. Apparently, now the entire dishwasher is—and I'm using her words here—'contaminated' with animal products. And it didn't stop there. Now she says the fridge has 'bacon grease fingers' on it because I eat bacon and then, God forbid, I touch the fridge handle. Now, I wash my hands! I'm not running around wiping grease on the appliances like a barbarian, but just the idea of it is enough to upset her.",
        //   "delivery": {"pace": "fast", "emotion": "frustrated", "pause_before_ms": 500, "overlap_previous": false}
        // },
        // {
        //   "speaker_id": "op",
        //   "text":
        //       "So now she's asked me and her mom to completely stop eating meat at home. Just… ban it from the house entirely. She says she's fine with the cheese and the butter being in the fridge, but it's specifically the meat that makes her feel sick. And frankly? I'm on team 'hell no.'",
        //   "delivery": {"pace": "normal", "emotion": "frustrated", "pause_before_ms": 600, "overlap_previous": false}
        // },
        // {
        //   "speaker_id": "speaker_2",
        //   "text":
        //       "I mean, N-T-A for sure. But if she's really worried about the 'tainted' dishwasher, why not just get her a special sponge? Let her wash her own dishes by hand so they never have to touch the communal soap. It's a great way to see how serious she actually is about the residue when she has to do the scrubbing herself.",
        //   "delivery": {"pace": "normal", "emotion": "calm", "pause_before_ms": 300, "overlap_previous": false}
        // },
        // {
        //   "speaker_id": "speaker_3",
        //   "text":
        //       "She needs a serious education on how dishwashers work. It's soap and high-heat water; nothing is surviving that. Honestly, she's being a bit of a brat. If I were you, I'd tally up the cost of those expensive substitutes and all the special gear she 'needs' to be self-sufficient and show her the bill.",
        //   "delivery": {"pace": "fast", "emotion": "frustrated", "pause_before_ms": 200, "overlap_previous": false}
        // },
        // {
        //   "speaker_id": "speaker_2",
        //   "text":
        //       "And look at the bright side—if you buy her all her own plates, soap, and sponges now, that's just less stuff she has to buy when she eventually moves out. It's a head start on adulting!",
        //   "delivery": {"pace": "normal", "emotion": "calm", "pause_before_ms": 150, "overlap_previous": false}
        // },
        // {
        //   "speaker_id": "op",
        //   "text":
        //       "See, that's where I'm at. But my wife… she's much more amenable. She's strongly pushing me to actually consider the request. Her reasoning is that both our parents live really close by, so we could just go to their houses whenever we want to eat meat. She doesn't want our daughter to feel 'uncomfortable' in her own kitchen. But man, I'm sorry… I love her, but she needs to learn to live side-by-side with people who are different. I'm not going to stop eating bacon in my own house.",
        //   "delivery": {"pace": "slow", "emotion": "frustrated", "pause_before_ms": 800, "overlap_previous": false}
        // }
      ].map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>)).toList();

      final speakers = (analysis['speakers'] as List).map((s) => Speaker.fromJson(s as Map<String, dynamic>)).toList();
      final voiceMap = VoiceAssignment.assignVoices(speakers);

      final tts = _ref.read(ttsServiceProvider);
      await tts.initialize();
      final synthesized = <TranscriptSegment>[];

      for (int i = 0; i < segments.length; i++) {
        state = state.copyWith(
          status: CreateStatus.synthesizing,
          progress: i / segments.length,
          currentSpeaker: segments[i].speakerId,
        );
        final seg = segments[i];
        final result = await tts.synthesizeSegment(
          segment: seg,
          voice: voiceMap[seg.speakerId] ?? 'am_adam',
          episodeId: episodeId,
          segmentIndex: i,
        );
        synthesized.add(seg.copyWith(audioFilePath: result.path, audioDuration: result.duration));
      }

      final timedSegments = _withAudioOffsets(synthesized);

      final durationSeconds = _episodeDurationSeconds(timedSegments);

      final docsDir = await getApplicationDocumentsDirectory();
      final episodeDir = Directory('${docsDir.path}/episodes/$episodeId');
      await episodeDir.create(recursive: true);
      final transcriptFile = File('${episodeDir.path}/transcript.json');
      final transcriptData = {
        'episode_title': analysis['episode_title'],
        'tone': analysis['tone'],
        'speakers': analysis['speakers'],
        'segments': timedSegments
            .map(
              (seg) => {
                'speaker_id': seg.speakerId,
                'text': seg.text,
                'delivery': {
                  'pace': seg.delivery.pace,
                  'emotion': seg.delivery.emotion,
                  'pause_before_ms': seg.delivery.pauseBeforeMs,
                  'overlap_previous': seg.delivery.overlapPrevious,
                },
                'audio_offset_ms': seg.audioOffset?.inMilliseconds,
                'audio_duration_ms': seg.audioDuration?.inMilliseconds,
              },
            )
            .toList(),
      };
      await transcriptFile.writeAsString(jsonEncode(transcriptData));
      final transcriptPath = transcriptFile.path;

      state = state.copyWith(status: CreateStatus.stitching, progress: null, currentSpeaker: null);
      final stitcher = _ref.read(audioStitcherProvider);
      final finalAudioPath = await stitcher.stitch(segments: timedSegments, episodeId: episodeId);

      final db = _ref.read(databaseProvider);
      await db.upsertEpisode(EpisodesCompanion(
        episodeId: Value(episodeId),
        title: Value(analysis['episode_title'] as String? ?? 'Untitled'),
        subreddit: Value(posts.first.subreddit),
        sourceUrlsJson: Value(AppDatabase.encodeUrls(urls)),
        tone: Value(analysis['tone'] as String? ?? 'talk_show'),
        createdAt: Value(DateTime.now()),
        durationSeconds: Value(durationSeconds),
        audioWavPath: Value(finalAudioPath),
        transcriptJsonPath: Value(transcriptPath),
        status: Value(AppDatabase.encodeStatus(EpisodeStatus.complete)),
      ));

      final episode = await db.episodeById(episodeId);
      state = state.copyWith(status: CreateStatus.complete, episode: episode);
    } on PlatformException catch (e) {
      final message = e.message?.trim();
      final details = message == null || message.isEmpty ? e.code : '${e.code}: $message';
      state = state.copyWith(status: CreateStatus.failed, error: details);
    } catch (e) {
      state = state.copyWith(status: CreateStatus.failed, error: e.toString());
    } finally {
      await WakelockPlus.disable();
    }
  }

  List<TranscriptSegment> _withAudioOffsets(List<TranscriptSegment> segments) {
    final timedSegments = <TranscriptSegment>[];
    var currentMs = 0;

    for (final segment in segments) {
      currentMs += segment.delivery.pauseBeforeMs;

      if (segment.delivery.overlapPrevious && timedSegments.isNotEmpty) {
        final previous = timedSegments.last;
        final previousEnd = previous.audioOffset!.inMilliseconds + previous.audioDuration!.inMilliseconds;
        currentMs = previousEnd - 500;
      }

      timedSegments.add(segment.copyWith(audioOffset: Duration(milliseconds: currentMs)));
      currentMs += segment.audioDuration!.inMilliseconds;
    }

    return timedSegments;
  }

  int _episodeDurationSeconds(List<TranscriptSegment> segments) {
    var totalMilliseconds = 0;

    for (final segment in segments) {
      final offsetMs = segment.audioOffset?.inMilliseconds ?? 0;
      final durationMs = segment.audioDuration?.inMilliseconds ?? 0;
      final segmentEndMs = offsetMs + durationMs;
      if (segmentEndMs > totalMilliseconds) {
        totalMilliseconds = segmentEndMs;
      }
    }

    return (totalMilliseconds / 1000).ceil();
  }
}

class CreateState {
  const CreateState._(
    this.status, {
    this.urls = const [],
    this.progress,
    this.currentSpeaker,
    this.partialAudioPath,
    this.episode,
    this.error,
    this.hasCheckedCompatibility = false,
  });

  const CreateState.idle() : this._(CreateStatus.idle);

  final CreateStatus status;
  final List<String> urls;
  final double? progress;
  final String? currentSpeaker;
  final String? partialAudioPath;
  final Episode? episode;
  final String? error;
  final bool hasCheckedCompatibility;

  CreateState copyWith({
    CreateStatus? status,
    List<String>? urls,
    double? progress,
    String? currentSpeaker,
    String? partialAudioPath,
    Episode? episode,
    String? error,
    bool? hasCheckedCompatibility,
  }) {
    return CreateState._(
      status ?? this.status,
      urls: urls ?? this.urls,
      progress: progress,
      currentSpeaker: currentSpeaker,
      partialAudioPath: partialAudioPath ?? this.partialAudioPath,
      episode: episode ?? this.episode,
      error: error,
      hasCheckedCompatibility: hasCheckedCompatibility ?? this.hasCheckedCompatibility,
    );
  }
}

enum CreateStatus {
  idle,
  checkingCompatibility,
  unsupported,
  scraping,
  analyzing,
  generatingTranscript,
  synthesizing,
  stitching,
  complete,
  failed,
}
