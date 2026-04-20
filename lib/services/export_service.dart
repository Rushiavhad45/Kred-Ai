// flutter_app/lib/services/export_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/enhanced_application_model.dart';
import '../models/prediction_result_model.dart';
import '../models/shap_explanation_model.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Export as PDF with proper error handling
  Future<String> exportToPdf({
    required EnhancedApplicationModel application,
    required PredictionResult predictionResult,
    ShapExplanation? explanation,
  }) async {
    try {
      final pdf = pw.Document();

      // Load logo with proper error handling
      pw.ImageProvider? logo;
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logo = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        print('Logo not found, continuing without logo: $e');
        // Continue without logo
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(logo, application),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            // Executive Summary
            _buildPdfSection('Assessment Summary', [
              _buildPdfKeyValueRow('Application ID', application.applicationId),
              _buildPdfKeyValueRow('Assessment Date', application.submissionTimestamp.toString().split(' ')[0]),
              _buildPdfKeyValueRow('Risk Category', predictionResult.riskCategory),
              _buildPdfKeyValueRow('Risk Probability', '${(predictionResult.riskProbability * 100).toStringAsFixed(1)}%'),
              _buildPdfKeyValueRow('Model Confidence', '${(predictionResult.confidence * 100).toStringAsFixed(1)}%'),
              _buildPdfKeyValueRow('Loan Status', predictionResult.loanStatus),
            ]),

            pw.SizedBox(height: 20),

            // Personal Information
            _buildPdfSection('Personal Information', [
              _buildPdfKeyValueRow('Full Name', application.userProfile.fullName),
              _buildPdfKeyValueRow('Age', '${application.userProfile.age} years'),
              _buildPdfKeyValueRow('Phone', application.userProfile.phoneNumber),
              _buildPdfKeyValueRow('Email', application.userProfile.emailAddress),
              _buildPdfKeyValueRow('Address', application.userProfile.fullAddress),
              if (application.userProfile.occupation != null)
                _buildPdfKeyValueRow('Occupation', application.userProfile.occupation!),
              if (application.userProfile.panNumber != null)
                _buildPdfKeyValueRow('PAN Number', application.userProfile.panNumber!),
            ]),

            pw.SizedBox(height: 20),

            // Financial Information
            _buildPdfSection('Financial Information', [
              _buildPdfKeyValueRow('Annual Income', '₹${application.applicationData.personIncome.toStringAsFixed(0)}'),
              _buildPdfKeyValueRow('Employment Length', '${application.applicationData.personEmpLength} years'),
              _buildPdfKeyValueRow('Loan Amount Requested', '₹${application.applicationData.loanAmnt.toStringAsFixed(0)}'),
              _buildPdfKeyValueRow('Interest Rate', '${application.applicationData.loanIntRate}%'),
              if (application.applicationData.loanIntent != null)
                _buildPdfKeyValueRow('Loan Purpose', application.applicationData.loanIntent!.toUpperCase()),
              _buildPdfKeyValueRow('Credit History Length', '${application.applicationData.cbPersonCredHistLength} years'),
            ]),

            pw.SizedBox(height: 20),

            // Risk Assessment Details
            _buildPdfSection('Risk Assessment Analysis', [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: predictionResult.isApproved 
                    ? const PdfColor(0.2, 0.8, 0.2, 0.1)
                    : const PdfColor(0.8, 0.2, 0.2, 0.1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Assessment Result: ${predictionResult.loanStatus}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: predictionResult.isApproved 
                          ? const PdfColor(0.2, 0.6, 0.2)
                          : const PdfColor(0.8, 0.2, 0.2),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Risk Level: ${predictionResult.riskCategory}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Risk Probability: ${(predictionResult.riskProbability * 100).toStringAsFixed(1)}%',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Model Confidence: ${(predictionResult.confidence * 100).toStringAsFixed(1)}%',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ]),

            pw.SizedBox(height: 20),

            // SHAP Explanation
            if (explanation != null) ...[
              _buildPdfSection('AI Explanation - Key Factors', [
                pw.Text(
                  'The following factors were most influential in your credit assessment:',
                  style: pw.TextStyle(fontSize: 12, color: const PdfColor(0.3, 0.3, 0.3)),
                ),
                pw.SizedBox(height: 10),
                ...explanation.readableExplanation.take(8).map((exp) =>
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(fontSize: 12)),
                        pw.Expanded(
                          child: pw.Text(exp, style: pw.TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ]),

              pw.SizedBox(height: 20),

              // Recommendations
              if (explanation.recommendations.isNotEmpty) ...[
                _buildPdfSection('Personalized Recommendations', [
                  ...explanation.recommendations.take(5).map((rec) =>
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: const PdfColor(0.8, 0.8, 0.8)),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            rec.title,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(rec.description, style: pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Action: ${rec.actionItem}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: const PdfColor(0.2, 0.4, 0.8),
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ]),
              ],
            ],

            pw.SizedBox(height: 20),

            // Disclaimer
            _buildPdfDisclaimer(),
          ],
        ),
      );

      // Save PDF with proper error handling
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'credit_assessment_${application.applicationId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      } catch (e) {
        print('Error saving PDF: $e');
        // Try external storage directory as fallback
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final fileName = 'credit_assessment_${application.applicationId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(await pdf.save());
          return file.path;
        } else {
          throw Exception('Could not access storage directories');
        }
      }
    } catch (e) {
      print('PDF Generation Error: $e');
      throw Exception('Failed to generate PDF: $e');
    }
  }

  // Export as Image with proper error handling
  Future<String> exportToImage({
    required GlobalKey repaintBoundaryKey,
    required String applicationId,
  }) async {
    try {
      final RenderRepaintBoundary boundary = 
          repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }
      
      final pngBytes = byteData.buffer.asUint8List();

      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'credit_assessment_${applicationId}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);
        return file.path;
      } catch (e) {
        // Try external storage as fallback
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final fileName = 'credit_assessment_${applicationId}_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pngBytes);
          return file.path;
        } else {
          throw Exception('Could not access storage directories');
        }
      }
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }

  // Share file with proper error handling
  Future<void> shareFile(String filePath, String title) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: title,
        subject: 'Credit Assessment Report',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  // PDF Helper methods with safe implementations
  pw.Widget _buildPdfHeader(pw.ImageProvider? logo, EnhancedApplicationModel application) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Image(logo, width: 40, height: 40)
              else
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    color: const PdfColor(0.08, 0.4, 0.75),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'KA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Credit Assessment Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Application ID',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                application.applicationId,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on ${DateTime.now().toString().split(' ')[0]}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'KredAI - Credit Risk Assessment System',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor(0.08, 0.4, 0.75),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.98, 0.98, 0.98),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfKeyValueRow(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            key,
            style: pw.TextStyle(
              fontSize: 12,
              color: const PdfColor(0.4, 0.4, 0.4),
            ),
          ),
          pw.Flexible(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor(1.0, 0.95, 0.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Important Disclaimer',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '• This assessment is for informational purposes only and does not constitute a guarantee of loan approval.\n'
            '• Final lending decisions are subject to additional verification and lender policies.\n'
            '• All personal and financial information is processed securely and in compliance with data protection regulations.\n'
            '• For questions about this assessment, please contact our support team.',
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
