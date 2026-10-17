import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/image_compressor.dart';

class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropDialog({super.key, required this.imageBytes});

  static Future<Uint8List?> show(BuildContext context, Uint8List imageBytes) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImageCropDialog(imageBytes: imageBytes),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final TransformationController _transformController = TransformationController();
  bool _processing = false;
  double _zoom = 1.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleZoomChange(double newZoom) {
    setState(() => _zoom = newZoom);
    final matrix = Matrix4.diagonal3Values(newZoom, newZoom, 1.0);
    _transformController.value = matrix;
  }

  Future<void> _handleCrop() async {
    setState(() => _processing = true);

    try {
      // Calculate crop from the transform matrix
      final matrix = _transformController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final translation = matrix.getTranslation();

      // Viewport is 280x280 square
      const double viewportSize = 280.0;

      // Inverse calculate visible region:
      // screenX = transX + imgX * scale  =>  imgX = (screenX - transX) / scale
      // Since viewport is centered in the 280x280 container:
      final leftOnImg = max(0.0, -translation.x / scale);
      final topOnImg = max(0.0, -translation.y / scale);
      final widthOnImg = viewportSize / scale;
      final heightOnImg = viewportSize / scale;

      // Normalize assuming standard image layout
      final normX = (leftOnImg / viewportSize).clamp(0.0, 0.95);
      final normY = (topOnImg / viewportSize).clamp(0.0, 0.95);
      final normW = (widthOnImg / viewportSize).clamp(0.05, 1.0 - normX);
      final normH = (heightOnImg / viewportSize).clamp(0.05, 1.0 - normY);

      final croppedAndCompressed = ImageCompressor.cropAndCompress(
        imageBytes: widget.imageBytes,
        normX: normX,
        normY: normY,
        normWidth: normW,
        normHeight: normH,
      );

      if (mounted) {
        Navigator.pop(context, croppedAndCompressed);
      }
    } catch (e) {
      // Fallback: direct compress
      final fallback = ImageCompressor.compressToMax10Kb(widget.imageBytes);
      if (mounted) {
        Navigator.pop(context, fallback);
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const double cropBoxSize = 260.0;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.crop_rounded, color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Crop Profile Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _processing ? null : () => Navigator.pop(context),
                  color: colors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pinch to zoom and drag to position your photo in the frame. Photo will be optimized to <= 10 KB.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 18),

            // Crop Box with interactive image preview
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: cropBoxSize,
                  height: cropBoxSize,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Interactive zoomed and panned image
                      InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 0.8,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: Image.memory(
                          widget.imageBytes,
                          width: cropBoxSize,
                          height: cropBoxSize,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Circular/Square crop guide overlay
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              // Subtle 3x3 grid
                              Column(
                                children: [
                                  const Spacer(),
                                  Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
                                  const Spacer(),
                                  Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
                                  const Spacer(),
                                ],
                              ),
                              Row(
                                children: [
                                  const Spacer(),
                                  VerticalDivider(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                  const Spacer(),
                                  VerticalDivider(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Zoom slider controls
            Row(
              children: [
                Icon(Icons.zoom_out_rounded, size: 20, color: colors.textSecondary),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 0.8,
                    max: 3.0,
                    activeColor: colors.primary,
                    inactiveColor: colors.border,
                    onChanged: _processing ? null : _handleZoomChange,
                  ),
                ),
                Icon(Icons.zoom_in_rounded, size: 20, color: colors.textSecondary),
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  tooltip: 'Reset Zoom',
                  color: colors.textSecondary,
                  onPressed: _processing
                      ? null
                      : () {
                          _handleZoomChange(1.0);
                        },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processing ? null : _handleCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _processing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Crop & Save',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
