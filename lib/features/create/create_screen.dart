import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:threadcast/shared/widgets/unsupported_device_screen.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createProvider.notifier).checkCompatibilityOnLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createProvider);
    final notifier = ref.read(createProvider.notifier);

    final isGenerating = {
      CreateStatus.scraping,
      CreateStatus.analyzing,
      CreateStatus.generatingTranscript,
      CreateStatus.synthesizing,
      CreateStatus.stitching,
    }.contains(state.status);

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
