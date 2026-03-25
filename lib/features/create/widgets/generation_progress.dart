import 'package:flutter/material.dart';

import '../create_provider.dart';

class GenerationProgress extends StatelessWidget {
  const GenerationProgress({super.key, required this.state});

  final CreateState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == CreateStatus.awaitingDownloadConsent) {
      return const SizedBox.shrink();
    }

    if (state.status == CreateStatus.modelDownloading) {
      final pct = state.downloadProgress ?? 0.0;
      final pctStr = '${(pct * 100).toStringAsFixed(0)}%';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Downloading AI model ($pctStr)…',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Keep the app open. If you close it, the download will resume next time.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: pct > 0 ? pct : null),
        ],
      );
    }

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
