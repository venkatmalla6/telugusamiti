import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.contains(':')) {
        setState(() => _isProcessing = true);
        
        final parts = code.split(':');
        if (parts.length >= 2) {
          final eventId = parts[0];
          final registrationId = parts[1];
          // Navigate to validation screen
          context.push('/volunteer/validate/$eventId/$registrationId').then((_) {
            if (mounted) {
              setState(() => _isProcessing = false);
            }
          });
        } else {
          _showError('Invalid QR Code Format');
        }
      } else {
        _showError('Unrecognized QR Code');
      }
    }
  }

  void _showError(String message) {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Event QR'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          // Scanner overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.primaryGold,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          
          // Instructions
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Align the QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
          
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    path.addRect(rect);
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ),
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Top left
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.top + borderRadius),
      Offset(cutOutRect.left, cutOutRect.top + borderLength),
      boxPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left + borderRadius, cutOutRect.top),
      Offset(cutOutRect.left + borderLength, cutOutRect.top),
      boxPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cutOutRect.left + borderRadius, cutOutRect.top + borderRadius), radius: borderRadius),
      3.14,
      1.57,
      false,
      boxPaint,
    );

    // Top right
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.top + borderRadius),
      Offset(cutOutRect.right, cutOutRect.top + borderLength),
      boxPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right - borderRadius, cutOutRect.top),
      Offset(cutOutRect.right - borderLength, cutOutRect.top),
      boxPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cutOutRect.right - borderRadius, cutOutRect.top + borderRadius), radius: borderRadius),
      -1.57,
      1.57,
      false,
      boxPaint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.bottom - borderRadius),
      Offset(cutOutRect.right, cutOutRect.bottom - borderLength),
      boxPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
      Offset(cutOutRect.right - borderLength, cutOutRect.bottom),
      boxPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cutOutRect.right - borderRadius, cutOutRect.bottom - borderRadius), radius: borderRadius),
      0,
      1.57,
      false,
      boxPaint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
      Offset(cutOutRect.left, cutOutRect.bottom - borderLength),
      boxPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left + borderRadius, cutOutRect.bottom),
      Offset(cutOutRect.left + borderLength, cutOutRect.bottom),
      boxPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cutOutRect.left + borderRadius, cutOutRect.bottom - borderRadius), radius: borderRadius),
      1.57,
      1.57,
      false,
      boxPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
