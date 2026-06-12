// lib/screens/locked_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note_model.dart';
import '../database/database_helper.dart';
import '../services/biometric_service.dart';
import 'add_edit_note_screen.dart';

class LockedNoteScreen extends StatefulWidget {
  final Note note;
  const LockedNoteScreen({super.key, required this.note});

  @override
  State<LockedNoteScreen> createState() => _LockedNoteScreenState();
}

class _LockedNoteScreenState extends State<LockedNoteScreen>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _biometricAvailable = false;
  bool _unlocked = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14, end: 14), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    // Check if biometric is available AND note allows it
    if (widget.note.useBiometric) {
      BiometricService.instance.isAvailable().then((available) {
        if (mounted) setState(() => _biometricAvailable = available);
        // Auto-prompt if available
        if (available) _tryBiometric();
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _navigateToEdit() {
    setState(() => _unlocked = true);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) =>
          AddEditNoteScreen(note: widget.note, dbHelper: DatabaseHelper.instance),
    ));
  }

  Future<void> _tryBiometric() async {
    final ok = await BiometricService.instance
        .authenticate(reason: 'Unlock "${widget.note.title}"');
    if (ok && mounted) _navigateToEdit();
  }

  void _verifyPin() {
    final entered = _pinController.text.trim();
    if (entered == widget.note.pinCode) {
      _navigateToEdit();
    } else {
      _shakeController.forward(from: 0);
      setState(() => _error = 'Incorrect PIN. Try again.');
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Note'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock icon
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                        color: cs.primaryContainer, shape: BoxShape.circle),
                    child: Icon(Icons.lock_rounded,
                        size: 48, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(height: 24),
                  Text('This note is protected',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Enter your PIN to unlock',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 32),

                  // PIN field
                  TextField(
                    controller: _pinController,
                    autofocus: !_biometricAvailable,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 12),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: const TextStyle(letterSpacing: 8),
                      errorText: _error,
                      counterText: '',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: (_) => _verifyPin(),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Unlock with PIN button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _unlocked ? null : _verifyPin,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Unlock with PIN'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  // Fingerprint button (shown only when available)
                  if (_biometricAvailable) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _unlocked ? null : _tryBiometric,
                        icon: const Icon(Icons.fingerprint_rounded, size: 22),
                        label: const Text('Use Fingerprint'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint_rounded,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text('Tap to authenticate with fingerprint',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
