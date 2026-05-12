import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../constants/cloudinary_constants.dart';
import '../../models/item_model.dart';
import '../../models/location_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/add_location_sheet.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  static const _categories = [
    'Tools',
    'Electronics',
    'Furniture',
    'Sports & Outdoors',
    'Vehicles',
    'Garden & Outdoor',
    'Kitchen & Appliances',
    'Clothing',
    'Books & Media',
    'Musical Instruments',
    'Party & Events',
    'Camping & Hiking',
    'Photography',
    'Gaming',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();

  final MapController _mapController = MapController();

  ItemCondition _condition = ItemCondition.good;
  String? _selectedCategory;
  LocationModel? _selectedLocation;
  List<XFile> _pickedImages = [];
  bool _isLoading = false;
  String? _errorMessage;

  static const _maxPhotos = 5;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;
    setState(() => _pickedImages.add(image));
  }

  void _showImageSourceSheet() {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages(String userId) async {
    final cloudinary = CloudinaryPublic(
      CloudinaryConstants.cloudName,
      CloudinaryConstants.uploadPreset,
      cache: false,
    );

    final urls = <String>[];
    for (final image in _pickedImages) {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: '${CloudinaryConstants.itemsFolder}/$userId',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      urls.add(response.secureUrl);
    }
    return urls;
  }

  void _showAddLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddLocationSheet(
        onSaved: (location) => setState(() => _selectedLocation = location),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      setState(() => _errorMessage = 'Please select a location.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = ref.read(authStateProvider).value!.uid;
      final photoUrls = await _uploadImages(userId);

      final item = ItemModel(
        id: '',
        ownerId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        photoUrls: photoUrls,
        category: _selectedCategory!,
        condition: _condition,
        pricePerDay: double.parse(_priceController.text.trim()),
        isAvailable: true,
        address: _selectedLocation!.toAddress(),
        locationLabel: _selectedLocation!.label,
        averageRating: 0.0,
        totalReviews: 0,
        createdAt: Timestamp.now(),
      );

      await ref.read(itemServiceProvider).addItem(item);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(userLocationsProvider);
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('List an Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (_) =>
                    _selectedCategory == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per day (€)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a price';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ItemCondition>(
                value: _condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: ItemCondition.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 20),
              Text('Photos', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < _pickedImages.length; i++)
                      _ImageThumb(
                        file: File(_pickedImages[i].path),
                        onRemove: () => _removeImage(i),
                      ),
                    if (_pickedImages.length < _maxPhotos)
                      _AddPhotoButton(
                        color: color,
                        onTap: _showImageSourceSheet,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showAddLocationSheet,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              locationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  'Could not load locations: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                data: (locations) {
                  if (locations.isEmpty) {
                    return _EmptyLocationsHint(onAdd: _showAddLocationSheet);
                  }
                  return DropdownButtonFormField<LocationModel>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Pick a location',
                    ),
                    items: locations
                        .map(
                          (loc) => DropdownMenuItem(
                            value: loc,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedLocation = v);
                      if (v != null) {
                        final ll = LatLng(
                          v.location.latitude,
                          v.location.longitude,
                        );
                        _mapController.move(ll, 15);
                      }
                    },
                    validator: (_) =>
                        _selectedLocation == null ? 'Select a location' : null,
                  );
                },
              ),
              if (_selectedLocation != null) ...[
                Text(
                  '${_selectedLocation?.street}, ${_selectedLocation?.city}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _selectedLocation!.location.latitude,
                          _selectedLocation!.location.longitude,
                        ),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.lender',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _selectedLocation!.location.latitude,
                                _selectedLocation!.location.longitude,
                              ),
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.location_pin,
                                color: color,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('List Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover, width: 100, height: 100),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: color, size: 28),
            const SizedBox(height: 4),
            Text('Add photo', style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _EmptyLocationsHint extends StatelessWidget {
  const _EmptyLocationsHint({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, color: color, size: 32),
          const SizedBox(height: 8),
          const Text(
            'You have no saved locations yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAdd,
            child: const Text('Add your first location'),
          ),
        ],
      ),
    );
  }
}
