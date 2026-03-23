import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../services/llm/models/transcript_file.dart';

class TranscriptView extends StatefulWidget {
  final String transcriptJsonPath;
  final Stream<Duration> positionStream;

  const TranscriptView({
    super.key,
    required this.transcriptJsonPath,
    required this.positionStream,
  });

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();

  TranscriptFile? _transcript;
  bool _hasLoaded = false;
  int _activeIndex = -1;

  static const _speakerColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
  ];

  @override
  void initState() {
    super.initState();
    _loadTranscript();
  }

  Future<void> _loadTranscript() async {
    try {
      final file = File(widget.transcriptJsonPath);
      if (!await file.exists()) {
        if (!mounted) return;
        setState(() => _hasLoaded = true);
        return;
      }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _transcript = TranscriptFile.fromJson(json);
        _hasLoaded = true;
      });
    } catch (e) {
      debugPrint('TranscriptView: failed to load transcript: $e');
      if (!mounted) return;
      setState(() => _hasLoaded = true);
    }
  }

  int _findActiveIndex(Duration position, List<PlayableSegment> segments) {
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final end = seg.audioOffset + seg.audioDuration;
      if (position >= seg.audioOffset && position < end) {
        return i;
      }
    }
    return -1;
  }

  int _visibleSegmentCount(Duration position, List<PlayableSegment> segments, int activeIndex) {
    if (activeIndex >= 0) {
      return activeIndex + 1;
    }

    for (int i = segments.length - 1; i >= 0; i--) {
      if (position >= segments[i].audioOffset) {
        return i + 1;
      }
    }

    return 0;
  }

  void _scrollToActive(int index) {
    if (!_scrollController.isAttached) return;
    _scrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0,
    );
  }

  Color _colorForSpeaker(String speakerId, List<TranscriptSpeaker> speakers) {
    final index = speakers.indexWhere((s) => s.id == speakerId);
    if (index < 0) return _speakerColors[0];
    return _speakerColors[index % _speakerColors.length];
  }

  String _nameForSpeaker(String speakerId, List<TranscriptSpeaker> speakers) {
    final matchIndex = speakers.indexWhere((s) => s.id == speakerId);
    if (matchIndex < 0) return 'Commenter';
    final speaker = speakers[matchIndex];
    if (speaker.role == 'main_speaker') return 'OP';
    return speaker.redditUsername ?? 'Commenter';
  }

  @override
  Widget build(BuildContext context) {
    final transcript = _transcript;
    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (transcript == null || transcript.segments.isEmpty) {
      return const Center(child: Text('No transcript available'));
    }

    return StreamBuilder<Duration>(
      stream: widget.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final newIndex = _findActiveIndex(position, transcript.segments);
        final visibleCount = _visibleSegmentCount(position, transcript.segments, newIndex);

        if (newIndex != _activeIndex) {
          _activeIndex = newIndex;
          if (newIndex >= 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _scrollToActive(newIndex);
              }
            });
          }
        }

        if (visibleCount == 0) {
          return const Center(child: Text('Transcript will appear as playback progresses'));
        }

        return ScrollablePositionedList.builder(
          itemCount: visibleCount,
          itemScrollController: _scrollController,
          itemPositionsListener: _positionsListener,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final segment = transcript.segments[index];
            final isActive = index == _activeIndex;
            final color = _colorForSpeaker(segment.speakerId, transcript.speakers);
            final name = _nameForSpeaker(segment.speakerId, transcript.speakers);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isActive ? Border.all(color: color.withValues(alpha: 0.3)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    segment.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
