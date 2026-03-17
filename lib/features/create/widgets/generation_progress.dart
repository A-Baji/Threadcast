import 'package:flutter/material.dart';

import '../create_provider.dart';

class GenerationProgress extends StatelessWidget {
  const GenerationProgress({super.key, required this.state});

  final CreateState state;

  @override
  Widget build(BuildContext context) {
    final labels = {
      CreateStatus.scraping: 'Fetching post...',
      CreateStatus.analyzing: 'Analyzing content...',
      CreateStatus.generatingTranscript: 'Writing transcript...',
      CreateStatus.synthesizing: 'Generating voices...',
      CreateStatus.stitching: 'Stitching audio...',
    };

    final label = labels[state.status];
    if (label == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        if (state.status == CreateStatus.synthesizing)
          LinearProgressIndicator(value: state.progress)
        else
          const LinearProgressIndicator(),
      ],
    );
  }
}
