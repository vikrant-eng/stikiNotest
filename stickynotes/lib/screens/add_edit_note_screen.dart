// lib/screens/add_edit_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note_model.dart';
import '../database/database_helper.dart';
import '../services/biometric_service.dart';

class _NoteColor {
  final String label;
  final int value;
  const _NoteColor(this.label, this.value);
}

const _kColors = [
  _NoteColor('Yellow', 0xFFFFF9C4),
  _NoteColor('Blue', 0xFFBBDEFB),
  _NoteColor('Green', 0xFFC8E6C9),
  _NoteColor('Pink', 0xFFF8BBD0),
  _NoteColor('Purple', 0xFFE1BEE7),
  _NoteColor('Orange', 0xFFFFE0B2),
];

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;
  final DatabaseHelper dbHelper;

  const AddEditNoteScreen({super.key, this.note, required this.dbHelper});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _contentFocus = FocusNode();

  late int _color;
  late bool _isProtected;
  String? _pinCode;
  bool _showPinField = false;
  bool _pinObscure = true;
  bool _useBiometric = false;
  bool _biometricAvailable = false;
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleCtrl.text = n?.title ?? '';
    _contentCtrl.text = n?.content ?? '';
    _color = n?.color ?? _kColors.first.value;
    _isProtected = n?.isProtected ?? false;
    _pinCode = n?.pinCode;
    _useBiometric = n?.useBiometric ?? false;
    _showPinField = _isProtected && _pinCode == null;
    BiometricService.instance
        .isAvailable()
        .then((v) { if (mounted) setState(() => _biometricAvailable = v); });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _pinCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<bool> _save() async {
    setState(() => _isSaving = true);
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) {
      _snack('Note is empty — nothing saved.');
      setState(() => _isSaving = false);
      return false;
    }
    if (_isProtected && _pinCode == null) {
      final pin = _pinCtrl.text.trim();
      if (pin.length != 4) {
        _snack('Please enter a valid 4-digit PIN.');
        setState(() => _isSaving = false);
        return false;
      }
      _pinCode = pin;
    }
    final note = Note(
      id: widget.note?.id,
      title: title,
      content: content,
      color: _color,
      createdAt: widget.note?.createdAt ?? DateTime.now().toIso8601String(),
      isProtected: _isProtected,
      pinCode: _isProtected ? _pinCode : null,
      useBiometric: _isProtected && _useBiometric,
    );
    if (_isEditing) {
      await widget.dbHelper.updateNote(note);
    } else {
      await widget.dbHelper.insertNote(note);
    }
    setState(() => _isSaving = false);
    return true;
  }

  Future<void> _saveAndPop() async {
    if (await _save() && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _changePinFlow() async {
    final pin = await _pinDialog('Set New PIN');
    if (pin == null) return;
    setState(() => _pinCode = pin);
    _snack('PIN updated.');
  }

  Future<void> _removePinFlow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Protection?'),
        content: const Text('PIN lock will be removed from this note.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _isProtected = false;
        _pinCode = null;
        _useBiometric = false;
        _showPinField = false;
        _pinCtrl.clear();
      });
      _snack('Protection removed.');
    }
  }

  Future<String?> _pinDialog(String title) async {
    final ctrl = TextEditingController();
    bool obs = true;
    String? err;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: TextField(
          controller: ctrl, autofocus: true, obscureText: obs,
          keyboardType: TextInputType.number, maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '4-digit PIN', errorText: err, counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(obs ? Icons.visibility_off : Icons.visibility),
              onPressed: () => set(() => obs = !obs),
            ),
          ),
          onChanged: (_) { if (err != null) set(() => err = null); },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.length != 4) { set(() => err = 'Must be exactly 4 digits'); return; }
              Navigator.pop(ctx, v);
            },
            child: const Text('Set PIN'),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color(_color);
    final lum = bg.computeLuminance();
    final fg = lum > 0.5 ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Note' : 'New Note',
            style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _saveAndPop,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: fg.withValues(alpha: 0.15),
                  foregroundColor: fg,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: _titleCtrl,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: fg.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_contentFocus),
              ),
              Divider(color: fg.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: 12),
              // Content
              TextField(
                controller: _contentCtrl,
                focusNode: _contentFocus,
                style: TextStyle(fontSize: 16, color: fg),
                decoration: InputDecoration(
                  hintText: 'Start typing your note…',
                  hintStyle: TextStyle(color: fg.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                ),
                maxLines: null,
                minLines: 10,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 24),
              // Color picker
              _label('Note Color', fg),
              const SizedBox(height: 10),
              _colorPicker(fg),
              const SizedBox(height: 24),
              // Security
              _label('Security', fg),
              const SizedBox(height: 8),
              _securityCard(cs, fg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color fg) => Text(text,
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          letterSpacing: 1.2, color: fg.withValues(alpha: 0.6)));

  Widget _colorPicker(Color fg) => Wrap(
    spacing: 10, runSpacing: 10,
    children: _kColors.map((nc) {
      final sel = _color == nc.value;
      return GestureDetector(
        onTap: () => setState(() => _color = nc.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Color(nc.value),
            shape: BoxShape.circle,
            border: sel
                ? Border.all(color: fg, width: 3)
                : Border.all(color: Colors.transparent, width: 3),
            boxShadow: [BoxShadow(
              color: Color(nc.value).withValues(alpha: 0.6),
              blurRadius: sel ? 8 : 2, spreadRadius: sel ? 1 : 0,
            )],
          ),
          child: sel ? Icon(Icons.check_rounded, size: 18, color: fg) : null,
        ),
      );
    }).toList(),
  );

  // ── Security card — uses Material so SwitchListTile ink works ────────────
  Widget _securityCard(ColorScheme cs, Color fg) {
    final surfaceColor = fg.withValues(alpha: 0.1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: surfaceColor,
        child: Column(
          children: [
            // PIN toggle
            SwitchListTile.adaptive(
              value: _isProtected,
              onChanged: (val) async {
                if (val) {
                  setState(() { _isProtected = true; _showPinField = true; _pinCode = null; });
                } else {
                  if (_pinCode != null) {
                    await _removePinFlow();
                  } else {
                    setState(() { _isProtected = false; _showPinField = false; _useBiometric = false; _pinCtrl.clear(); });
                  }
                }
              },
              title: Text('PIN Protection',
                  style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
              subtitle: Text(
                _isProtected
                    ? (_pinCode != null ? 'Note is locked' : 'Enter a PIN below')
                    : 'Enable to lock this note',
                style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6)),
              ),
              secondary: Icon(Icons.security_rounded, color: fg),
              activeThumbColor: cs.primary,
            ),

            // PIN input field (new lock being set up)
            if (_isProtected && _showPinField && _pinCode == null) ...[
              Divider(color: fg.withValues(alpha: 0.15), height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: TextField(
                  controller: _pinCtrl,
                  obscureText: _pinObscure,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: fg, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'Enter 4-digit PIN',
                    labelStyle: TextStyle(color: fg.withValues(alpha: 0.7)),
                    counterText: '',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: fg.withValues(alpha: 0.4))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: fg.withValues(alpha: 0.3))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: fg)),
                    suffixIcon: IconButton(
                      icon: Icon(_pinObscure ? Icons.visibility_off : Icons.visibility, color: fg),
                      onPressed: () => setState(() => _pinObscure = !_pinObscure),
                    ),
                  ),
                ),
              ),
            ],

            // Biometric toggle (only when PIN is active and device supports it)
            if (_isProtected && (_pinCode != null || !_showPinField) && _biometricAvailable) ...[
              Divider(color: fg.withValues(alpha: 0.15), height: 1),
              SwitchListTile.adaptive(
                value: _useBiometric,
                onChanged: (val) => setState(() => _useBiometric = val),
                title: Text('Fingerprint Unlock',
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
                subtitle: Text(
                  _useBiometric
                      ? 'Fingerprint can unlock this note'
                      : 'Allow fingerprint as alternative',
                  style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6)),
                ),
                secondary: Icon(Icons.fingerprint_rounded, color: fg),
                activeThumbColor: cs.primary,
              ),
            ],

            // Change / Remove PIN buttons
            if (_isProtected && _pinCode != null) ...[
              Divider(color: fg.withValues(alpha: 0.15), height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _changePinFlow,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Change PIN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: fg,
                        side: BorderSide(color: fg.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removePinFlow,
                      icon: const Icon(Icons.lock_open_rounded, size: 16),
                      label: const Text('Remove PIN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}