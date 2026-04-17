import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/qr_code_service.dart';
import '../../theme/spacing.dart';

/// QR Code Scanner Screen
///
/// Allows users to scan QR codes for payments or upload from gallery
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final QrCodeService _qrService = QrCodeService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isFlashOn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);

      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // In a real app, you would use qr_flutter_scan or similar to decode image
      // For now, we'll show a placeholder message
      _showError(
          'Decodificação de imagem QR não implementada ainda. Use câmera para escanear.');
      setState(() => _isProcessing = false);
    } catch (e) {
      _showError('Erro ao selecionar imagem: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    // TODO: Toggle camera flash
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código QR'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera preview placeholder
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: BJBankSpacing.md),
                  Text(
                    'Aponte a câmara para um código QR',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: BJBankSpacing.md),
                  Text(
                    'Integração com mobile_scanner em desenvolvimento',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Flash button
          Positioned(
            top: BJBankSpacing.md,
            right: BJBankSpacing.md,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: _toggleFlash,
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gallery button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      icon: const Icon(Icons.image),
                      label: const Text('Selecionar da Galeria'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          vertical: BJBankSpacing.md,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: BJBankSpacing.sm),

                  // Scanner tips
                  Container(
                    padding: const EdgeInsets.all(BJBankSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '💡 Dicas de escanagem:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Certifique-se que o QR está bem iluminado',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          '• Mantenha a câmara estável a ~15cm do código',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          '• O código inteiro deve ser visível no visor',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
