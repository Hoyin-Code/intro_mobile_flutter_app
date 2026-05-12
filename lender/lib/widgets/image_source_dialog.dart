import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> showImageSourceDialog(
  BuildContext context, {
  required String title,
  required void Function(ImageSource) onPick,
}) {
  return showDialog(
    context: context,
    useRootNavigator: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.of(dialogContext).pop();
              onPick(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.of(dialogContext).pop();
              onPick(ImageSource.camera);
            },
          ),
        ],
      ),
    ),
  );
}
