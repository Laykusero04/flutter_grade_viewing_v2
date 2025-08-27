import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc.dart';
import '../../components/constants/app_color.dart';
import '../../components/constants/app_text_styles.dart';
import '../../models/qr_session.dart';
import '../../service/firestore_subject_teacher_qr_service.dart';
import '../../service/firestore_subject_service.dart';
import '../../models/subject.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    try {
      // Parse QR data
      final qrMap = _parseQRData(qrData);
      if (qrMap == null) {
        _showError('Invalid QR code format');
        return;
      }

      // Validate QR session
      final session = await FirestoreSubjectTeacherQRService.getQRSession(qrMap['subjectTeacherId']!);
      if (session == null) {
        _showError('Invalid QR session');
        return;
      }

      if (!session.canEnroll) {
        if (session.currentEnrollments >= session.maxEnrollments) {
          _showError('Enrollment limit reached for this session');
        } else {
          _showError('QR session is inactive');
        }
        return;
      }

      // Get subject details
      final subject = await FirestoreSubjectService.getSubjectById(session.subjectId);
      if (subject == null) {
        _showError('Subject not found');
        return;
      }

      // Show enrollment confirmation
      _showEnrollmentConfirmation(session, subject);

    } catch (e) {
      _showError('Error processing QR code: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Map<String, String>? _parseQRData(String qrData) {
    try {
      final parts = qrData.split('|');
      final Map<String, String> result = {};
      
      for (final part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          result[keyValue[0]] = keyValue[1];
        }
      }

      // Validate required fields
      if (result.containsKey('type') && 
          result.containsKey('subjectTeacherId') && 
          result.containsKey('subjectId') && 
          result.containsKey('teacherId')) {
        return result;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showEnrollmentConfirmation(QRSession session, Subject subject) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Enrollment',
          style: AppTextStyles.headline.copyWith(fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to enroll in this subject?',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Subject', subject.name),
            _buildInfoRow('Code', subject.code),
            if (subject.department != null) _buildInfoRow('Department', subject.department!),
            if (subject.credits != null) _buildInfoRow('Credits', subject.credits.toString()),
            _buildInfoRow('Teacher', session.teacherId),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _enrollStudent(session),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enrollStudent(QRSession session) async {
    try {
      // Get current user
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        _showError('User not authenticated');
        return;
      }

      final studentId = authState.user.uid;
      final studentEmail = authState.user.email ?? '';

      // Enroll student
      final result = await FirestoreSubjectTeacherQRService.enrollStudent(
        subjectTeacherId: session.subjectTeacherId,
        studentId: studentId,
        studentEmail: studentEmail,
        studentName: '${authState.user.firstName ?? ''} ${authState.user.lastName ?? ''}'.trim(),
      );

      Navigator.of(context).pop(); // Close confirmation dialog

      if (result['success'] == true) {
        _showSuccess('Successfully enrolled in subject!');
      } else {
        _showError(result['error'] ?? 'Enrollment failed');
      }

    } catch (e) {
      Navigator.of(context).pop(); // Close confirmation dialog
      _showError('Error during enrollment: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.active,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _resetScanner();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Scanner',
          style: AppTextStyles.headline.copyWith(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColor.primary.withOpacity(0.1),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: AppColor.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan Teacher\'s QR Code',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Point your camera at the QR code displayed by your teacher',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Camera View
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),
                
                // Scanning overlay
                if (_isScanning)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColor.primary,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColor.primary, width: 2),
                              left: BorderSide(color: AppColor.primary, width: 2),
                              right: BorderSide(color: AppColor.primary, width: 2),
                              bottom: BorderSide(color: AppColor.primary, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Processing indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Processing QR Code...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
