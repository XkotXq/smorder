import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';

/// A photo picked for an order, already read into memory - XFile has no
/// usable path on web, so bytes are the one representation that works on
/// both targets (see OrdersApi.uploadPhoto).
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.filename, required this.contentType});
  final Uint8List bytes;
  final String filename;
  final String contentType;

  double get sizeKb => bytes.length / 1024;
}

/// "Zdjęcie" on a new order - take one with the camera or pick it from the
/// gallery, see it as a thumbnail, drop it again. Optional: a transport is
/// placed with or without it.
///
/// The picture is shrunk here, on the device ([_maxWidth]/[_quality]), not
/// server-side: a phone camera's 12 MP original is several megabytes over
/// warehouse Wi-Fi for no gain, since this is only ever looked at as
/// evidence of what was collected.
class PhotoField extends StatefulWidget {
  const PhotoField({super.key, required this.photo, required this.onChanged});

  final PickedPhoto? photo;
  final ValueChanged<PickedPhoto?> onChanged;

  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

const _maxWidth = 1600.0;
const _quality = 70;

class _PhotoFieldState extends State<PhotoField> {
  final _picker = ImagePicker();
  bool _picking = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(source: source, maxWidth: _maxWidth, imageQuality: _quality);
      if (file == null) return; // cancelled - not an error
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      widget.onChanged(
        PickedPhoto(
          bytes: bytes,
          filename: file.name.isEmpty ? 'photo.jpg' : file.name,
          // XFile.mimeType is null on plenty of Android devices; the picker
          // re-encodes to JPEG whenever imageQuality is set anyway, so that
          // is the honest default rather than guessing from the extension.
          contentType: file.mimeType ?? 'image/jpeg',
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = context.t.orders.newOrder.photoError);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.newOrder;
    final photo = widget.photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.photo, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (photo == null)
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: _picking ? null : () => _pick(ImageSource.camera),
                  leading: const Icon(LucideIcons.camera, size: 18),
                  child: Text(t.photoTake),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton.outline(
                  onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                  leading: const Icon(LucideIcons.image, size: 18),
                  child: Text(t.photoPick),
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(photo.bytes, width: 64, height: 64, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(photo.filename, style: theme.textTheme.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${photo.sizeKb.round()} kB', style: theme.textTheme.muted.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onChanged(null),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(LucideIcons.trash2, size: 18, color: theme.colorScheme.destructive),
                  ),
                ),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive)),
        ],
      ],
    );
  }
}
