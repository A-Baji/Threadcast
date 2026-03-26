import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:threadcast/shared/widgets/unsupported_device_screen.dart';

import '../../core/constants.dart';
import 'create_provider.dart';
import 'widgets/generation_progress.dart';
import 'widgets/url_chip_list.dart';
import 'widgets/url_input_field.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  bool _bannerDismissed = false;

  bool _isGeneratingStatus(CreateStatus status) {
    return {
      CreateStatus.awaitingDownloadConsent,
      CreateStatus.modelDownloading,
      CreateStatus.scraping,
      CreateStatus.analyzing,
      CreateStatus.generatingTranscript,
      CreateStatus.synthesizing,
      CreateStatus.stitching,
    }.contains(status);
  }

  void _showDownloadConsentDialog(BuildContext context) {
    final notifier = ref.read(createProvider.notifier);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('One-time download required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your device's built-in AI isn't available, so Threadcast needs "
              'to download a local AI model the first time you generate a podcast.',
            ),
            SizedBox(height: 16),
            Text(
              'Download size: ${AppConstants.gemmaModelDisplaySize}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'We recommend Wi-Fi. The model is saved permanently to your device '
              'and reused automatically — you will never be asked to download it again. '
              'If the download is interrupted, it will resume where it left off.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.cancelDownload();
            },
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.confirmDownload();
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createProvider.notifier).checkCompatibilityOnLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes outside of the build return.
    // ref.listen triggers a callback whenever the provider's value changes.
    ref.listen<CreateState>(createProvider, (previous, next) {
      if (next.status == CreateStatus.complete && next.episode != null) {
        // Navigate to the player for the newly created episode.
        // context.push keeps the Create screen in the back stack so the user
        // can return to it and create another episode.
        context.push('/player/${next.episode!.episodeId}');
      }

      if (next.status == CreateStatus.awaitingDownloadConsent &&
          previous?.status != CreateStatus.awaitingDownloadConsent) {
        _showDownloadConsentDialog(context);
      }

      final wasGenerating = previous != null && _isGeneratingStatus(previous.status);
      final isGeneratingNow = _isGeneratingStatus(next.status);
      if (wasGenerating && !isGeneratingNow && _bannerDismissed && mounted) {
        setState(() {
          _bannerDismissed = false;
        });
      }
    });

    final state = ref.watch(createProvider);
    final notifier = ref.read(createProvider.notifier);

    final isGenerating = _isGeneratingStatus(state.status);

    if (state.status == CreateStatus.checkingCompatibility) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Podcast')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == CreateStatus.unsupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Podcast')),
        body: const UnsupportedDeviceScreen(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Podcast')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGenerating && !_bannerDismissed) ...[
                MaterialBanner(
                  padding: const EdgeInsets.all(16),
                  content: const Text(
                    'Keep Threadcast open while generating. The screen will stay on.',
                  ),
                  backgroundColor: Colors.amber.shade100,
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _bannerDismissed = true;
                        });
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              UrlInputField(onSubmit: notifier.addUrl),
              const SizedBox(height: 16),
              if (state.urls.isNotEmpty)
                Text('Source URLs (${state.urls.length})', style: Theme.of(context).textTheme.titleMedium),
              if (state.urls.isNotEmpty) const SizedBox(height: 8),
              Expanded(
                child: state.urls.isEmpty
                    ? const SizedBox.shrink()
                    : UrlChipList(
                        urls: state.urls,
                        onRemove: notifier.removeUrl,
                        onReorder: notifier.reorderUrls,
                      ),
              ),
              GenerationProgress(state: state),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.urls.isEmpty || isGenerating ? null : notifier.generatePodcast,
                  child: const Text('Generate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
