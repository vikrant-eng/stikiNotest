// lib/widgets/pin_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A dialog that asks the user to enter a 4-digit PIN.
/// Returns the entered PIN string or null if dismissed.
class PinDialog extends StatefulWidget {
  final String title;
  final String? errorText;

  const PinDialog({
    super.key,
    required this.title,
    this.errorText,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinDialog(title: title),
    );
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _errorText = widget.errorText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length != 4) {
      setState(() => _errorText = 'Please enter a 4-digit PIN');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.lock_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '4-digit PIN',
              hintText: '••••',
              errorText: _errorText,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
