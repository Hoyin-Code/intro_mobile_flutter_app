import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../models/location_model.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';

class AddLocationSheet extends ConsumerStatefulWidget {
  const AddLocationSheet({super.key, required this.onSaved});

  final ValueChanged<LocationModel> onSaved;

  @override
  ConsumerState<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<AddLocationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = ref.read(authStateProvider).value!.uid;

      final street = _streetController.text.trim();
      final city = _cityController.text.trim();
      final postalCode = _postalCodeController.text.trim();
      final country = _countryController.text.trim();

      final results = await locationFromAddress(
        '$street, $city, $postalCode, $country',
      );
      if (results.isEmpty) {
        setState(() => _errorMessage = 'Address not found. Check the details and try again.');
        return;
      }
      final geoPoint = GeoPoint(results.first.latitude, results.first.longitude);

      final draft = LocationModel(
        id: '',
        label: _labelController.text.trim(),
        street: street,
        city: city,
        postalCode: postalCode,
        country: country,
        location: geoPoint,
      );

      final docRef = await ref
          .read(locationServiceProvider)
          .addLocation(userId, draft);

      final saved = LocationModel(
        id: docRef.id,
        label: draft.label,
        street: draft.street,
        city: draft.city,
        postalCode: draft.postalCode,
        country: draft.country,
        location: draft.location,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved(saved);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New location',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label (e.g. Home, Work)'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.isEmpty ? 'Enter a label' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street'),
              validator: (v) => v == null || v.isEmpty ? 'Enter a street' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(labelText: 'Postal code'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: 'Country'),
              validator: (v) => v == null || v.isEmpty ? 'Enter a country' : null,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save location'),
            ),
          ],
        ),
      ),
    );
  }
}
