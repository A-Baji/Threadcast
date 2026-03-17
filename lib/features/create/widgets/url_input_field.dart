import 'package:flutter/material.dart';

class UrlInputField extends StatefulWidget {
  const UrlInputField({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? _]) {
    if (_formKey.currentState?.validate() ?? false) {
      final value = _controller.text.trim();
      widget.onSubmit(value);
      _controller.clear();
    }
  }

  bool _isValidRedditUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.contains('reddit.com') || uri.host == 'redd.it';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Reddit URL',
                hintText: 'https://www.reddit.com/r/...',
              ),
              validator: (val) => val != null && _isValidRedditUrl(val) ? null : 'Must be a Reddit URL',
              onFieldSubmitted: _submit,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _submit,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
