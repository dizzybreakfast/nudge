import 'package:flutter/material.dart';
import 'package:nudge/models/account.dart';

class PersonalIslandWidget extends StatefulWidget {
  final Account account;
  final VoidCallback onSignOut;

  const PersonalIslandWidget({
    super.key,
    required this.account,
    required this.onSignOut,
  });

  @override
  State<PersonalIslandWidget> createState() => _PersonalIslandWidgetState();
}

class _PersonalIslandWidgetState extends State<PersonalIslandWidget> {
  bool _keepScreenOn = false;
  bool _useLargeTexts = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.account.apiName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.account.apiEmail != null && widget.account.apiEmail!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                child: Text(widget.account.apiEmail!),
              )
            else
              const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Keep screen on'),
              value: _keepScreenOn,
              onChanged: (bool value) {
                setState(() {
                  _keepScreenOn = value;
                  // TODO: Implement keep screen on functionality
                });
              },
            ),
            SwitchListTile(
              title: const Text('Use large texts'),
              value: _useLargeTexts,
              onChanged: (bool value) {
                setState(() {
                  _useLargeTexts = value;
                  // TODO: Implement use large texts functionality
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onSignOut,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
