import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../../models/qr_session.dart';
import '../../models/subject.dart';
import '../../service/firestore_subject_teacher_qr_service.dart';

class QRCodeModal extends StatefulWidget {
  final QRSession qrSession;
  final Subject subject;
  final VoidCallback? onClose;

  const QRCodeModal({
    super.key,
    required this.qrSession,
    required this.subject,
    this.onClose,
  });

  @override
  State<QRCodeModal> createState() => _QRCodeModalState();
}

class _QRCodeModalState extends State<QRCodeModal> {
  late QRSession _qrSession;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _qrSession = widget.qrSession;
  }

  Future<void> _toggleQRStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = await FirestoreSubjectTeacherQRService.toggleQREnrollmentStatus(
        _qrSession.subjectTeacherId,
      );

      if (newStatus != null) {
        setState(() {
          _qrSession = _qrSession.copyWith(isActive: newStatus);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'QR enrollment is now ${newStatus ? 'ACTIVE' : 'INACTIVE'}',
              ),
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update QR status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = {
      'type': 'subject_enrollment',
      'subjectTeacherId': _qrSession.subjectTeacherId,
      'subjectId': _qrSession.subjectId,
      'teacherId': _qrSession.teacherId,
    };

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'QR Code for ${widget.subject.name}',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // QR Status Indicator with Toggle
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _qrSession.isActive ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _qrSession.isActive ? Colors.green[300]! : Colors.red[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _qrSession.isActive ? Icons.check_circle : Icons.cancel,
                              color: _qrSession.isActive ? Colors.green[700] : Colors.red[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _qrSession.isActive ? 'QR Code Active' : 'QR Code Inactive',
                                    style: AppTextStyles.headline.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _qrSession.isActive ? Colors.green[700] : Colors.red[700],
                                    ),
                                  ),
                                  Text(
                                    _qrSession.isActive 
                                        ? 'Students can scan and enroll'
                                        : 'Students cannot enroll at this time',
                                    style: AppTextStyles.body.copyWith(
                                      color: _qrSession.isActive ? Colors.green[600] : Colors.red[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Text(
                                  _qrSession.isActive ? 'ON' : 'OFF',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _qrSession.isActive ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_isLoading)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                    ),
                                  )
                                else
                                  Switch(
                                    value: _qrSession.isActive,
                                    onChanged: (value) => _toggleQRStatus(),
                                    activeColor: Colors.green,
                                    inactiveThumbColor: Colors.red[300],
                                    inactiveTrackColor: Colors.red[100],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: PrettyQrView.data(
                            data: _encodeQRData(qrData),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Session Info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Information',
                              style: AppTextStyles.headline.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Subject', widget.subject.name),
                            _buildInfoRow('Code', widget.subject.code),
                            _buildInfoRow('Assignment ID', _qrSession.subjectTeacherId.substring(0, 8)),
                            _buildInfoRow('Assigned', _formatDateTime(_qrSession.assignedAt)),
                            _buildInfoRow('Enrollments', '${_qrSession.currentEnrollments}/${_qrSession.maxEnrollments}'),
                            _buildInfoRow('Status', _qrSession.isActive ? 'Active' : 'Inactive'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Instructions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Instructions for Students',
                                    style: AppTextStyles.headline.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Open the student app\n'
                              '2. Go to QR Scanner\n'
                              '3. Scan this QR code\n'
                              '4. Confirm enrollment',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.blue[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Close Button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
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
              label,
              style: AppTextStyles.body.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _encodeQRData(Map<String, dynamic> data) {
    // Convert the map to a JSON string for QR encoding
    final jsonString = data.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    return jsonString;
  }
}
